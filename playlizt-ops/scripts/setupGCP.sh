#!/bin/bash
set -e

# Determine Project Root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source credentials
if [ -f ~/gcp/credentials_playlizt ]; then
    source ~/gcp/credentials_playlizt
else
    echo "Error: ~/gcp/credentials_playlizt file not found!"
    exit 1
fi

if [ -z "$GEMINI_API_KEY" ]; then
    echo "Error: GEMINI_API_KEY is not set in ~/gcp/credentials_playlizt"
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
cd "$PROJECT_ROOT/playlizt-terraform"
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

# Generate Tag
IMAGE_TAG=$(date +%s)
echo "Deploying with TAG: $IMAGE_TAG"

# Build and Push Images
REPO_PREFIX="${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT_ID}/playlizt-repo"
echo "Building and Pushing Images to ${REPO_PREFIX}..."

build_push() {
    IMAGE_NAME=$1      # logical service/image name, e.g. playlizt-content-api
    DOCKER_DIR=$2      # directory containing Dockerfile, e.g. playlizt-content/playlizt-content-api
    BUILD_ARGS=$3
    IMAGE_LATEST="${REPO_PREFIX}/${IMAGE_NAME}:latest"
    IMAGE_TAGGED="${REPO_PREFIX}/${IMAGE_NAME}:${IMAGE_TAG}"

    echo "------------------------------------------------"
    echo "Building $IMAGE_NAME from ${DOCKER_DIR}/Dockerfile..."
    echo "------------------------------------------------"

    (cd "$PROJECT_ROOT" && docker build --platform linux/amd64 -t "$IMAGE_LATEST" -t "$IMAGE_TAGGED" -f "${DOCKER_DIR}/Dockerfile" $BUILD_ARGS .)

    # Push both tags
    echo "Pushing images..."
    docker push "$IMAGE_LATEST"
    docker push "$IMAGE_TAGGED"
}

build_push "playlizt-eureka-service" "playlizt-eureka-service" "--build-arg SERVER_PORT=4761"
build_push "playlizt-authentication" "playlizt-authentication" "--build-arg SERVER_PORT=4081"
build_push "playlizt-content-api" "playlizt-content/playlizt-content-api" "--build-arg SERVER_PORT=4082"
build_push "playlizt-playback" "playlizt-playback" "--build-arg SERVER_PORT=4083"
build_push "playlizt-content-processing" "playlizt-content/playlizt-content-processing" "--build-arg SERVER_PORT=4084"
build_push "playlizt-api-gateway" "playlizt-api-gateway" "--build-arg SERVER_PORT=4080"
build_push "playlizt-frontend" "playlizt-frontend" ""

# Full Deployment
echo "Deploying all resources via Terraform..."
terraform apply \
  -var="project_id=$GCP_PROJECT_ID" \
  -var="region=$GCP_REGION" \
  -var="db_password=$DB_PASSWORD" \
  -var="jwt_secret=$JWT_SECRET" \
  -var="gemini_api_key=$GEMINI_API_KEY" \
  -var="image_tag=$IMAGE_TAG" \
  -auto-approve

echo "================================================"
echo "GCP Setup Complete!"
echo "================================================"
terraform output
exit 0
