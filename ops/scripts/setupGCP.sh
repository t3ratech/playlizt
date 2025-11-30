#!/bin/bash
set -e

# Determine Project Root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source credentials
if [ -f ~/gcp/credentials ]; then
    source ~/gcp/credentials
else
    echo "Error: ~/gcp/credentials file not found!"
    exit 1
fi

if [ -z "$GEMINI_API_KEY" ]; then
    echo "Error: GEMINI_API_KEY is not set in ~/gcp/credentials"
    exit 1
fi

# Check dependencies
if ! command -v gcloud &> /dev/null; then
    echo "Error: gcloud CLI is not installed. Please run $SCRIPT_DIR/setupLocal.sh first."
    exit 1
fi

if ! command -v terraform &> /dev/null; then
    echo "Error: terraform is not installed. Please run $SCRIPT_DIR/setupLocal.sh first."
    exit 1
fi

echo "Setting up GCP Infrastructure for Project: $GCP_PROJECT_ID"

# Authentication Check
echo "Checking Google Cloud authentication..."
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    echo "Not authenticated. Starting login flow..."
    gcloud auth login
else
    echo "Already authenticated (CLI)."
fi

# Check for Application Default Credentials (ADC) which Terraform needs
if [ ! -f "$HOME/.config/gcloud/application_default_credentials.json" ]; then
    echo "Application Default Credentials not found. Running ADC login..."
    gcloud auth application-default login
else
    echo "ADC already configured."
fi

# Set Project
echo "Setting active project to $GCP_PROJECT_ID..."
gcloud config set project "$GCP_PROJECT_ID"

# Initialize Terraform
cd "$PROJECT_ROOT/terraform"
terraform init

# Create Artifact Registry first
echo "Creating Artifact Registry..."
terraform apply -target=google_artifact_registry_repository.playlizt_repo \
  -var="project_id=$GCP_PROJECT_ID" \
  -var="region=$GCP_REGION" \
  -var="db_password=$DB_PASSWORD" \
  -var="jwt_secret=$JWT_SECRET" \
  -var="gemini_api_key=$GEMINI_API_KEY" \
  -auto-approve

# Configure Docker
echo "Configuring Docker authentication..."
gcloud auth configure-docker "${GCP_REGION}-docker.pkg.dev" --quiet

# Build and Push Images
REPO_PREFIX="${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT_ID}/playlizt-repo"
echo "Building and Pushing Images to ${REPO_PREFIX}..."

build_push() {
    SERVICE=$1
    BUILD_ARGS=$2
    IMAGE="${REPO_PREFIX}/${SERVICE}:latest"

    echo "------------------------------------------------"
    echo "Checking if $SERVICE needs rebuild..."
    echo "------------------------------------------------"

    # Build locally (but DO NOT push yet)
    (cd "$PROJECT_ROOT" && docker build --platform linux/amd64 -t "$IMAGE" -f "${SERVICE}/Dockerfile" $BUILD_ARGS .)

    # Get local digest (safely handle case where RepoDigests might be empty)
    LOCAL_DIGEST=$(docker inspect --format='{{if .RepoDigests}}{{index .RepoDigests 0}}{{end}}' "$IMAGE" 2>/dev/null | sed 's/.*@//' || true)

    # Get remote digest
    REMOTE_DIGEST=$(gcloud artifacts docker images describe "$IMAGE" \
        --project "$GCP_PROJECT_ID" \
        --location "$GCP_REGION" \
        --format="value(image_summary.digest)" 2>/dev/null || true)

    echo "Local Digest : $LOCAL_DIGEST"
    echo "Remote Digest: $REMOTE_DIGEST"

    # Compare
    if [[ "$LOCAL_DIGEST" == "$REMOTE_DIGEST" && -n "$LOCAL_DIGEST" ]]; then
        echo "🚀 No changes detected in $SERVICE — skipping docker push."
    else
        echo "🆕 Changes detected — pushing new image..."
        docker push "$IMAGE"
    fi
}

build_push "eureka-service" "--build-arg SERVER_PORT=4761"
build_push "auth-service" "--build-arg SERVER_PORT=4081"
build_push "content-service" "--build-arg SERVER_PORT=4082"
build_push "playback-service" "--build-arg SERVER_PORT=4083"
build_push "ai-service" "--build-arg SERVER_PORT=4084"
build_push "api-gateway" "--build-arg SERVER_PORT=4080"
build_push "frontend"

# Full Deployment
echo "Deploying all resources via Terraform..."
terraform apply \
  -var="project_id=$GCP_PROJECT_ID" \
  -var="region=$GCP_REGION" \
  -var="db_password=$DB_PASSWORD" \
  -var="jwt_secret=$JWT_SECRET" \
  -var="gemini_api_key=$GEMINI_API_KEY" \
  -auto-approve

echo "================================================"
echo "GCP Setup Complete!"
echo "================================================"
terraform output
exit 0
