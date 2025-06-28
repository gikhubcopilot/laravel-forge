#!/bin/bash

# Build script for universal shrk Docker image

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
IMAGE_NAME="shrk-universal"
IMAGE_TAG="latest"

log() {
    echo "[BUILD] $1"
}

error() {
    echo "[BUILD] ERROR: $1" >&2
}

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -t, --tag TAG     Set image tag (default: latest)"
    echo "  -n, --name NAME   Set image name (default: shrk-universal)"
    echo "  --no-cache        Build without using cache"
    echo "  --test            Run test after build"
    echo "  -h, --help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                          # Build with default settings"
    echo "  $0 -t v1.0 --test          # Build with tag v1.0 and run test"
    echo "  $0 --no-cache              # Build without cache"
}

# Parse command line arguments
NO_CACHE=""
RUN_TEST=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--tag)
            IMAGE_TAG="$2"
            shift 2
            ;;
        -n|--name)
            IMAGE_NAME="$2"
            shift 2
            ;;
        --no-cache)
            NO_CACHE="--no-cache"
            shift
            ;;
        --test)
            RUN_TEST=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

FULL_IMAGE_NAME="$IMAGE_NAME:$IMAGE_TAG"

log "Building universal shrk Docker image..."
log "Image name: $FULL_IMAGE_NAME"
log "Project root: $PROJECT_ROOT"

# Change to project root
cd "$PROJECT_ROOT"

# Make scripts executable
chmod +x scripts/*.sh

# Build the Docker image
log "Running docker build..."
if ! docker build $NO_CACHE -f Dockerfile.universal -t "$FULL_IMAGE_NAME" .; then
    error "Docker build failed"
    exit 1
fi

log "Build completed successfully!"
log "Image: $FULL_IMAGE_NAME"

# Show image size
IMAGE_SIZE=$(docker images "$FULL_IMAGE_NAME" --format "table {{.Size}}" | tail -n 1)
log "Image size: $IMAGE_SIZE"

# Run test if requested
if [ "$RUN_TEST" = true ]; then
    log "Running test..."
    
    # Test the image by running it briefly
    log "Testing container startup..."
    CONTAINER_ID=$(docker run -d --privileged "$FULL_IMAGE_NAME")
    
    # Wait a few seconds for startup
    sleep 5
    
    # Check if container is still running
    if docker ps -q --filter "id=$CONTAINER_ID" | grep -q .; then
        log "Container started successfully"
        
        # Get logs to see if environment detection worked
        log "Container logs:"
        docker logs "$CONTAINER_ID" 2>&1 | head -20
        
        # Stop the container
        docker stop "$CONTAINER_ID" >/dev/null
        docker rm "$CONTAINER_ID" >/dev/null
        
        log "Test completed successfully!"
    else
        error "Container failed to start or exited unexpectedly"
        docker logs "$CONTAINER_ID" 2>&1
        docker rm "$CONTAINER_ID" >/dev/null
        exit 1
    fi
fi

log "All done! You can now run the image with:"
log "  docker run --privileged -p 8080:8080 $FULL_IMAGE_NAME"
log ""
log "For production use, consider:"
log "  docker run -d --privileged --restart unless-stopped -p 8080:8080 $FULL_IMAGE_NAME"
