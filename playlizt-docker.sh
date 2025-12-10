#!/bin/bash

# Playlizt Docker Management Script
# Created in Windsurf Editor
# AI-Powered Streaming Platform
# Date: 2025-11-24

set -e

# =============================================================================
# CONFIGURATION
# =============================================================================

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Service definitions - list in dependency order
declare -a SERVICES=(
    "playlizt-database"
    "playlizt-eureka-service"
    "playlizt-authentication"
    "playlizt-content-api"
    "playlizt-playback"
    "playlizt-content-processing"
    "playlizt-api-gateway"
)

# Services that have JAR files to build
declare -A SERVICES_WITH_JAR=(
    ["playlizt-eureka-service"]=1
    ["playlizt-authentication"]=1
    ["playlizt-content-api"]=1
    ["playlizt-playback"]=1
    ["playlizt-content-processing"]=1
    ["playlizt-api-gateway"]=1
)

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Print usage information
print_usage() {
    echo -e "${BLUE}Playlizt Docker Management Script${NC}"
    echo ""
    echo "Usage: $0 [OPTIONS] [ACTION] [SERVICES...]"
    echo ""
    echo "Actions:"
    echo "  -r    [services]     Restart services"
    echo "  -rr   [services]     Redeploy + Restart services"
    echo "  -rrr  [services]     Rebuild + Redeploy + Restart services"
    echo "  -rrrr [services]     Recreate + Rebuild + Redeploy + Restart services"
    echo ""
    echo "Options:"
    echo "  -d, --detach         Run in detached mode (default)"
    echo "  -a, --attach         Run in attached mode"
    echo "  --rebuild-all        Rebuild all services in dependency order"
    echo "  --restart-all        Restart all services"
    echo "  --recreate-all       Recreate + Rebuild + Redeploy + Restart all services"
    echo "  --status             Show service status"
    echo "  --logs [service]     Show logs for a service (default: last 500 lines)"
    echo "    Log Options:"
    echo "      --tail <N|all>   Show the last N lines or all lines (default: 500)"
    echo "      -f, --follow     Follow log output"
    echo "  --test [unit|integration|all]   Run test suite (default: unit)"
    echo "  --tests <pattern>    Filter tests (Gradle --tests syntax)"
    echo "  --module <name>      Target specific module for tests (e.g., playlizt-ui-tests)"
    echo "  --test-unit          Alias for --test unit"
    echo "  --test-integration   Run integration tests"
    echo "  --test-all           Run all tests"
    echo "  --coverage           Run tests with coverage report"
    echo "  --cleanup            Stop and remove all containers"
    echo "  --build-web          Build Flutter web application"
    echo "  --serve-web [port]   Serve Flutter web application (default: 4090)"
    echo "  --stop-web           Stop Flutter web application"
    echo "  --build-apk          Build Flutter Android APK"
    echo "  --build-bundle       Build Flutter App Bundle (for Play Store)"
    echo "  --deploy             Deploy to Google Cloud Platform"
    echo "  --destroy-all        Stop, remove containers and volumes"
    echo "  --full-cleanup       Stop, remove containers, volumes and prune system"
    echo "  -h, --help           Show this help message"
    echo ""
    echo "Services: ${SERVICES[*]}"
    echo ""
    echo "Examples:"
    echo "  $0 -rrr playlizt-authentication playlizt-content-api    # Rebuild auth and content services"
    echo "  $0 -rr playlizt-database                                # Redeploy database"
    echo "  $0 --logs playlizt-authentication                       # Show auth service logs"
    echo "  $0 --test-all                                           # Run all tests"
    echo "  $0 --coverage                                           # Run tests with coverage"
    echo "  $0 --recreate-all                                       # Recreate all services"
}

# Use modern docker compose command
DOCKER_COMPOSE="docker compose"

# Load environment variables
source_env() {
    if [ -f "$SCRIPT_DIR/.env" ]; then
        echo -e "${BLUE}Loading environment variables...${NC}"
        set -a
        source "$SCRIPT_DIR/.env"
        set +a
    else
        echo -e "${RED}Error: .env file not found${NC}"
        echo -e "${YELLOW}Please create .env from .env.example:${NC}"
        echo -e "  cp .env.example .env"
        echo -e "  nano .env  # Fill required values"
        exit 1
    fi
}

# Check if service is valid
is_valid_service() {
    local service=$1
    for s in "${SERVICES[@]}"; do
        if [ "$s" = "$service" ]; then
            return 0
        fi
    done
    return 1
}

# Check if service has a JAR file
service_has_jar() {
    local service=$1
    [ "${SERVICES_WITH_JAR[$service]}" = "1" ]
}

# =============================================================================
# CORE SERVICE MANAGEMENT FUNCTIONS
# =============================================================================

# Wait for service to be healthy
wait_for_service_health() {
    local service=$1
    local max_retries=60
    local retry_count=0
    
    echo -e "${BLUE}Waiting for $service to be healthy...${NC}"
    
    while [ $retry_count -lt $max_retries ]; do
        # Check if container is running
        if ! docker compose ps "$service" 2>/dev/null | grep -q "Up"; then
            echo -e "${YELLOW}$service is not running yet...${NC}"
            sleep 2
            retry_count=$((retry_count + 1))
            continue
        fi
        
        # Service-specific health checks
        case "$service" in
            playlizt-database)
                if docker compose exec -T "$service" pg_isready -U "${PLAYLIZT_DB_USER}" >/dev/null 2>&1; then
                    echo -e "${GREEN}$service is healthy${NC}"
                    return 0
                fi
                ;;
            playlizt-eureka-service)
                if docker compose exec -T "$service" curl -f http://localhost:${PLAYLIZT_EUREKA_PORT}/actuator/health >/dev/null 2>&1; then
                    echo -e "${GREEN}$service is healthy${NC}"
                    return 0
                fi
                ;;
            playlizt-authentication|playlizt-content-api|playlizt-playback|playlizt-content-processing|playlizt-api-gateway)
                local port=""
                case "$service" in
                    playlizt-authentication) port=${PLAYLIZT_AUTH_PORT} ;;
                    playlizt-content-api) port=${PLAYLIZT_CONTENT_API_PORT} ;;
                    playlizt-playback) port=${PLAYLIZT_PLAYBACK_PORT} ;;
                    playlizt-content-processing) port=${PLAYLIZT_CONTENT_PROCESSING_PORT} ;;
                    playlizt-api-gateway) port=${PLAYLIZT_API_GATEWAY_PORT} ;;
                esac
                if docker compose exec -T "$service" curl -f http://localhost:$port/actuator/health >/dev/null 2>&1; then
                    echo -e "${GREEN}$service is healthy${NC}"
                    return 0
                fi
                ;;
        esac
        
        if [ $((retry_count % 10)) -eq 0 ]; then
            echo -e "${YELLOW}Still waiting for $service... (${retry_count}/${max_retries})${NC}"
        fi
        
        sleep 2
        retry_count=$((retry_count + 1))
    done
    
    echo -e "${RED}$service failed to become healthy after $max_retries attempts${NC}"
    echo -e "${YELLOW}Showing last 30 lines of logs:${NC}"
    docker compose logs --tail=30 "$service"
    return 1
}

# Stop service
stop_service() {
    local service=$1
    echo -e "${BLUE}Stopping $service...${NC}"
    docker compose stop "$service"
}

# Remove service container
remove_service() {
    local service=$1
    echo -e "${BLUE}Removing $service container...${NC}"
    docker compose rm -f -s "$service"
}

# Build service JAR
build_service_jar() {
    local service=$1
    echo -e "${BLUE}Building JAR for $service...${NC}"
    cd "$SCRIPT_DIR"

    # Map Docker service name to Gradle project path
    local projectPath=":$service"
    if [ "$service" = "playlizt-content-processing" ]; then
        projectPath=":playlizt-content:playlizt-content-processing"
    fi

    ./gradlew "${projectPath}:clean" "${projectPath}:bootJar" --no-daemon
}

# Build service Docker image
build_service_image() {
    local service=$1
    echo -e "${BLUE}Building Docker image for $service...${NC}"
    docker compose build --no-cache "$service"
}

# Start service
start_service() {
    local service=$1
    local mode=${2:-"-d"}
    echo -e "${BLUE}Starting $service...${NC}"
    docker compose up $mode "$service"
}

# =============================================================================
# REBUILD LEVEL FUNCTIONS
# =============================================================================

# Level 1: Restart (-r)
restart_service() {
    local service=$1
    echo -e "${CYAN}=== Level 1: Restarting $service ===${NC}"
    docker compose restart "$service"
    wait_for_service_health "$service"
}

# Level 2: Redeploy + Restart (-rr)
redeploy_service() {
    local service=$1
    echo -e "${CYAN}=== Level 2: Redeploying $service ===${NC}"
    stop_service "$service"
    remove_service "$service"
    start_service "$service" "-d"
    wait_for_service_health "$service"
}

# Level 3: Rebuild + Redeploy + Restart (-rrr)
rebuild_service() {
    local service=$1
    echo -e "${CYAN}=== Level 3: Rebuilding $service ===${NC}"
    
    if service_has_jar "$service"; then
        build_service_jar "$service"
    fi
    
    stop_service "$service"
    remove_service "$service"
    build_service_image "$service"
    start_service "$service" "-d"
    wait_for_service_health "$service"
}

# Level 4: Recreate + Rebuild + Redeploy + Restart (-rrrr)
recreate_service() {
    local service=$1
    echo -e "${CYAN}=== Level 4: Recreating $service ===${NC}"
    
    if service_has_jar "$service"; then
        build_service_jar "$service"
    fi
    
    stop_service "$service"
    remove_service "$service"
    
    # Remove volumes if database
    if [ "$service" = "playlizt-database" ]; then
        echo -e "${YELLOW}Removing database volume...${NC}"
        docker volume rm playlizt_playlizt-db-data 2>/dev/null || true
    fi
    
    build_service_image "$service"
    start_service "$service" "-d"
    wait_for_service_health "$service"
}

# =============================================================================
# BATCH OPERATIONS
# =============================================================================

# Rebuild all services
rebuild_all() {
    local api_url=${1}
    echo -e "${CYAN}=== Rebuilding all services in dependency order ===${NC}"
    source_env
    for service in "${SERVICES[@]}"; do
        rebuild_service "$service"
    done
    
    # Rebuild web app
    build_flutter_web "$api_url"
    
    echo -e "${GREEN}All services rebuilt successfully${NC}"
}

# Restart all services
restart_all() {
    echo -e "${CYAN}=== Restarting all services ===${NC}"
    docker compose restart
    echo -e "${GREEN}All services restarted${NC}"
}

# Recreate all services
recreate_all() {
    echo -e "${CYAN}=== Recreating all services in dependency order ===${NC}"
    source_env
    
    for service in "${SERVICES[@]}"; do
        recreate_service "$service"
    done
    
    echo -e "${GREEN}All services recreated successfully${NC}"
}

# =============================================================================
# TESTING FUNCTIONS
# =============================================================================

# Run unit tests
run_unit_tests() {
    local test_pattern=${1:-""}
    local module=${2:-""}
    echo -e "${CYAN}=== Running unit tests ===${NC}"
    cd "$SCRIPT_DIR"
    
    local gradle_task="test"
    if [ -n "$module" ]; then
        gradle_task=":$module:test"
        echo -e "${BLUE}Targeting module: $module${NC}"
    fi
    
    if [ -n "$test_pattern" ]; then
        echo -e "${BLUE}Running tests matching: $test_pattern${NC}"
        ./gradlew "$gradle_task" --tests "$test_pattern" --no-daemon
    else
        ./gradlew "$gradle_task" --no-daemon
    fi
}

# Run integration tests
run_integration_tests() {
    local test_pattern=${1:-""}
    local module=${2:-""}
    echo -e "${CYAN}=== Running integration tests ===${NC}"
    cd "$SCRIPT_DIR"
    
    local gradle_task="integrationTest"
    if [ -n "$module" ]; then
        gradle_task=":$module:integrationTest"
        echo -e "${BLUE}Targeting module: $module${NC}"
    fi
    
    if [ -n "$test_pattern" ]; then
        echo -e "${BLUE}Running integration tests matching: $test_pattern${NC}"
        ./gradlew "$gradle_task" --tests "$test_pattern" --no-daemon 2>/dev/null || echo -e "${YELLOW}No integration tests configured yet${NC}"
    else
        ./gradlew "$gradle_task" --no-daemon 2>/dev/null || echo -e "${YELLOW}No integration tests configured yet${NC}"
    fi
}

# Setup test environment
setup_test_env() {
    echo -e "${CYAN}=== Setting up Test Environment ===${NC}"
    
    # Start backend services and build frontend for local API
    echo -e "${BLUE}Starting backend services...${NC}"
    source_env
    
    if [ -z "${PLAYLIZT_API_GATEWAY_PORT}" ]; then
        echo -e "${RED}PLAYLIZT_API_GATEWAY_PORT is not set in .env; cannot build frontend for tests${NC}"
        exit 1
    fi
    
    local api_url="http://localhost:${PLAYLIZT_API_GATEWAY_PORT}/api/v1"
    echo -e "${BLUE}Building Flutter web for local tests with API_URL: ${api_url}${NC}"
    build_flutter_web "${api_url}"
    
    docker compose up -d
    
    # Wait for critical services
    wait_for_service_health "playlizt-database"
    wait_for_service_health "playlizt-eureka-service"
    wait_for_service_health "playlizt-authentication"
    wait_for_service_health "playlizt-content-api"
    wait_for_service_health "playlizt-playback"
    wait_for_service_health "playlizt-content-processing"
    wait_for_service_health "playlizt-api-gateway"
    
    # Start frontend
    serve_flutter_web 4090
    
    echo -e "${GREEN}Test environment ready${NC}"
}

# Teardown test environment
teardown_test_env() {
    echo -e "${CYAN}=== Tearing down Test Environment ===${NC}"
    stop_flutter_web
    docker compose stop
    echo -e "${GREEN}Test environment stopped${NC}"
}

# Run all tests
run_all_tests() {
    local test_pattern=${1:-""}
    local module=${2:-""}
    
    echo -e "${CYAN}=== Running all tests with environment ===${NC}"
    
    # Setup environment
    setup_test_env
    
    cd "$SCRIPT_DIR"
    
    local tasks="test"
    if [ -n "$module" ]; then
        tasks=":$module:test"
        echo -e "${BLUE}Targeting module: $module${NC}"
    fi
    
    local exit_code=0
    if [ -n "$test_pattern" ]; then
        echo -e "${BLUE}Running all tests matching: $test_pattern${NC}"
        ./gradlew $tasks --tests "$test_pattern" --no-daemon || exit_code=$?
    else
        ./gradlew $tasks --no-daemon || exit_code=$?
    fi
    
    # Teardown
    teardown_test_env
    
    if [ $exit_code -ne 0 ]; then
        echo -e "${RED}Tests failed!${NC}"
        return $exit_code
    fi
    echo -e "${GREEN}All tests passed!${NC}"
}

# Run tests with coverage
run_coverage() {
    echo -e "${CYAN}=== Running tests with coverage ===${NC}"
    cd "$SCRIPT_DIR"
    ./gradlew test jacocoTestReport --no-daemon
    
    echo -e "${GREEN}Coverage reports generated:${NC}"
    find . -name "index.html" -path "*/jacocoHtml/*" | while read -r report; do
        echo -e "  file://$SCRIPT_DIR/$report"
    done
}

# Build Flutter web
build_flutter_web() {
    local api_url=${1}
    echo -e "${CYAN}=== Building Flutter Web ===${NC}"
    cd "$SCRIPT_DIR/playlizt-frontend/playlizt_app"
    
    if ! command -v flutter &> /dev/null; then
        echo -e "${RED}Flutter not installed. Please install Flutter first.${NC}"
        echo -e "${YELLOW}Visit: https://flutter.dev/docs/get-started/install${NC}"
        return 1
    fi
    
    flutter pub get
    
    if [ -n "$api_url" ]; then
        echo -e "${BLUE}Building with API_URL: $api_url${NC}"
        flutter build web --release --dart-define=API_URL="$api_url"
    else
        echo -e "${BLUE}Building with default API URL (localhost)${NC}"
        flutter build web --release
    fi
    
    echo -e "${GREEN}Flutter web build complete!${NC}"
    echo -e "${BLUE}Output: $SCRIPT_DIR/playlizt-frontend/playlizt_app/build/web${NC}"
}

# Build Flutter APK
build_flutter_apk() {
    echo -e "${CYAN}=== Building Flutter APK ===${NC}"
    cd "$SCRIPT_DIR/playlizt-frontend/playlizt_app"
    
    if ! command -v flutter &> /dev/null; then
        echo -e "${RED}Flutter not installed. Please install Flutter first.${NC}"
        echo -e "${YELLOW}Visit: https://flutter.dev/docs/get-started/install${NC}"
        return 1
    fi
    
    flutter pub get
    flutter build apk --release
    
    echo -e "${GREEN}Flutter APK build complete!${NC}"
    echo -e "${BLUE}Output: $SCRIPT_DIR/playlizt-frontend/playlizt_app/build/app/outputs/flutter-apk/app-release.apk${NC}"
    
    local apk_size=$(du -h "$SCRIPT_DIR/playlizt-frontend/playlizt_app/build/app/outputs/flutter-apk/app-release.apk" 2>/dev/null | cut -f1)
    echo -e "${GREEN}APK Size: ${apk_size}${NC}"
}

# Build Flutter app bundle
build_flutter_bundle() {
    echo -e "${CYAN}=== Building Flutter App Bundle ===${NC}"
    cd "$SCRIPT_DIR/playlizt-frontend/playlizt_app"
    
    if ! command -v flutter &> /dev/null; then
        echo -e "${RED}Flutter not installed. Please install Flutter first.${NC}"
        return 1
    fi
    
    flutter pub get
    flutter build appbundle --release
    
    echo -e "${GREEN}Flutter App Bundle build complete!${NC}"
    echo -e "${BLUE}Output: $SCRIPT_DIR/playlizt-frontend/playlizt_app/build/app/outputs/bundle/release/app-release.aab${NC}"
}

# Deploy to GCP
deploy() {
    echo -e "${CYAN}=== Deploying to Google Cloud ===${NC}"
    
    # Fetch API Gateway URL
    echo -e "${BLUE}Fetching API Gateway URL...${NC}"
    local api_url=$(cd "$SCRIPT_DIR/playlizt-terraform" && terraform output -raw api_gateway_url 2>/dev/null || echo "")
    
    if [ -n "$api_url" ]; then
        api_url="${api_url}/api/v1"
        echo -e "${GREEN}Found URL: $api_url${NC}"
    else
        echo -e "${RED}API Gateway URL not found in Terraform outputs. Aborting deploy.${NC}"
        exit 1
    fi
    
    # Build Web with PROD URL
    build_flutter_web "$api_url"

    local deploy_script="$SCRIPT_DIR/playlizt-ops/scripts/setupGCP.sh"
    
    if [ ! -f "$deploy_script" ]; then
        echo -e "${RED}Deployment script not found: $deploy_script${NC}"
        exit 1
    fi
    
    # Ensure executable
    chmod +x "$deploy_script"
    
    # Run deployment
    "$deploy_script"
}

# Serve Flutter web
serve_flutter_web() {
    local port=${1:-4090}
    local web_dir="$SCRIPT_DIR/playlizt-frontend/playlizt_app/build/web"
    local pid_file="$SCRIPT_DIR/playlizt-frontend/playlizt_app/.web_server.pid"
    
    if [ -f "$pid_file" ]; then
        if ps -p $(cat "$pid_file") > /dev/null; then
            echo -e "${YELLOW}Web server is already running on PID $(cat "$pid_file")${NC}"
            return 0
        else
            rm "$pid_file"
        fi
    fi
    
    if [ ! -d "$web_dir" ]; then
        echo -e "${YELLOW}Web build not found. Building first...${NC}"
        build_flutter_web
    fi
    
    echo -e "${CYAN}=== Serving Flutter Web on port $port ===${NC}"
    cd "$web_dir"
    nohup python3 -m http.server "$port" > "$SCRIPT_DIR/playlizt-frontend/playlizt_app/web_server.log" 2>&1 &
    echo $! > "$pid_file"
    
    echo -e "${GREEN}Web server started on port $port (PID: $(cat "$pid_file"))${NC}"
    echo -e "${BLUE}Logs: $SCRIPT_DIR/playlizt-frontend/playlizt_app/web_server.log${NC}"
}

# Stop Flutter web
stop_flutter_web() {
    local pid_file="$SCRIPT_DIR/playlizt-frontend/playlizt_app/.web_server.pid"
    
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        echo -e "${CYAN}=== Stopping Web Server (PID: $pid) ===${NC}"
        kill "$pid" 2>/dev/null || true
        rm "$pid_file"
        echo -e "${GREEN}Web server stopped${NC}"
    else
        echo -e "${YELLOW}No web server running${NC}"
    fi
}

# =============================================================================
# UTILITY OPERATIONS
# =============================================================================

# Show service status
show_status() {
    echo -e "${CYAN}=== Playlizt Services Status ===${NC}"
    docker compose ps
    
    echo -e "\n${CYAN}=== Resource Usage ===${NC}"
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"
}

# Show logs
show_logs() {
    local service=${1:-""}
    local tail_lines=${2:-500}
    local follow=${3:-false}
    
    if [ -z "$service" ]; then
        echo -e "${YELLOW}Please specify a service${NC}"
        echo "Available services: ${SERVICES[*]}"
        return 1
    fi
    
    if ! is_valid_service "$service"; then
        echo -e "${RED}Invalid service: $service${NC}"
        echo "Available services: ${SERVICES[*]}"
        return 1
    fi
    
    echo -e "${CYAN}=== Logs for $service ===${NC}"
    
    if [ "$follow" = "true" ]; then
        docker compose logs -f --tail="$tail_lines" "$service"
    else
        docker compose logs --tail="$tail_lines" "$service"
    fi
}

# Cleanup operations
cleanup() {
    echo -e "${YELLOW}=== Stopping and removing all containers ===${NC}"
    docker compose down
    echo -e "${GREEN}Cleanup complete${NC}"
}

destroy_all() {
    echo -e "${YELLOW}=== Destroying all containers and volumes ===${NC}"
    docker compose down -v
    echo -e "${GREEN}Destroy complete${NC}"
}

full_cleanup() {
    echo -e "${YELLOW}=== Full cleanup: containers, volumes, and system prune ===${NC}"
    docker compose down -v
    docker system prune -f
    echo -e "${GREEN}Full cleanup complete${NC}"
}

# =============================================================================
# MAIN SCRIPT LOGIC
# =============================================================================

main() {
    if [ $# -eq 0 ]; then
        print_usage
        exit 0
    fi
    
    local action=""
    local services=()
    local detach_mode="-d"
    local test_pattern=""
    local test_module=""
    local tail_lines=500
    local follow_logs=false
    local api_url=""
    
    # Parse arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            -h|--help)
                print_usage
                exit 0
                ;;
            -r|-rr|-rrr|-rrrr)
                action="$1"
                shift
                ;;
            -d|--detach)
                detach_mode="-d"
                shift
                ;;
            -a|--attach)
                detach_mode=""
                shift
                ;;
            --api-url)
                shift
                api_url="$1"
                shift
                ;;
            --rebuild-all)
                rebuild_all "$api_url"
                exit 0
                ;;
            --restart-all)
                restart_all
                exit 0
                ;;
            --recreate-all)
                recreate_all
                exit 0
                ;;
            --status)
                show_status
                exit 0
                ;;
            --logs)
                shift
                local log_service=""
                while [ $# -gt 0 ]; do
                    case "$1" in
                        --tail)
                            shift
                            tail_lines="$1"
                            shift
                            ;;
                        -f|--follow)
                            follow_logs=true
                            shift
                            ;;
                        *)
                            log_service="$1"
                            shift
                            break
                            ;;
                    esac
                done
                show_logs "$log_service" "$tail_lines" "$follow_logs"
                exit 0
                ;;
            --test)
                shift
                local test_type=${1:-unit}
                shift
                case "$test_type" in
                    unit) run_unit_tests "$test_pattern" "$test_module" ;;
                    integration) run_integration_tests "$test_pattern" "$test_module" ;;
                    all) run_all_tests "$test_pattern" "$test_module" ;;
                    *) echo -e "${RED}Invalid test type: $test_type${NC}"; exit 1 ;;
                esac
                exit 0
                ;;
            --tests)
                shift
                test_pattern="$1"
                shift
                ;;
            --module)
                shift
                test_module="$1"
                shift
                ;;
            --test-unit)
                run_unit_tests "$test_pattern" "$test_module"
                exit 0
                ;;
            --test-integration)
                run_integration_tests "$test_pattern" "$test_module"
                exit 0
                ;;
            --test-all)
                run_all_tests "$test_pattern" "$test_module"
                exit 0
                ;;
            --coverage)
                run_coverage
                exit 0
                ;;
            --build-web)
                build_flutter_web "$api_url"
                exit 0
                ;;
            --serve-web)
                shift
                local port=""
                if [ -n "$1" ] && [[ "$1" =~ ^[0-9]+$ ]]; then
                    port="$1"
                    shift
                fi
                serve_flutter_web "$port"
                exit 0
                ;;
            --stop-web)
                stop_flutter_web
                exit 0
                ;;
            --build-apk)
                build_flutter_apk
                exit 0
                ;;
            --build-bundle)
                build_flutter_bundle
                exit 0
                ;;
            --deploy)
                deploy
                exit 0
                ;;
            --cleanup)
                cleanup
                exit 0
                ;;
            --destroy-all)
                destroy_all
                exit 0
                ;;
            --full-cleanup)
                full_cleanup
                exit 0
                ;;
            *)
                if is_valid_service "$1"; then
                    services+=("$1")
                else
                    echo -e "${RED}Unknown option or invalid service: $1${NC}"
                    print_usage
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Execute action on services
    if [ -n "$action" ]; then
        source_env
        
        if [ ${#services[@]} -eq 0 ]; then
            echo -e "${RED}No services specified${NC}"
            print_usage
            exit 1
        fi
        
        for service in "${services[@]}"; do
            case "$action" in
                -r) restart_service "$service" ;;
                -rr) redeploy_service "$service" ;;
                -rrr) rebuild_service "$service" ;;
                -rrrr) recreate_service "$service" ;;
            esac
        done
        
        echo -e "${GREEN}Operation completed successfully${NC}"
    fi
}

# Run main function
main "$@"
