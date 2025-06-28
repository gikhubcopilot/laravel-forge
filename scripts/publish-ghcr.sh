#!/bin/bash

# Script to publish shrk-universal to GitHub Container Registry (GHCR)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Default values - customize these
DEFAULT_GITHUB_USERNAME=""
DEFAULT_IMAGE_NAME="shrk-universal"
DEFAULT_TAG="latest"

log() {
    echo "[PUBLISH] $1"
}

error() {
    echo "[PUBLISH] ERROR: $1" >&2
}

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -u, --username USER   GitHub username (required)"
    echo "  -n, --name NAME       Image name (default: shrk-universal)"
    echo "  -t, --tag TAG         Image tag (default: latest)"
    echo "  --token TOKEN         GitHub Personal Access Token"
    echo "  --build               Build image before publishing"
    echo "  --dry-run             Show commands without executing"
    echo "  -h, --help            Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  GITHUB_TOKEN          GitHub Personal Access Token"
    echo "  GITHUB_USERNAME       GitHub username"
    echo ""
    echo "Examples:"
    echo "  $0 -u myusername --build"
    echo "  $0 -u myusername -n my-shrk -t v1.0"
    echo "  GITHUB_TOKEN=ghp_xxx $0 -u myusername"
}

# Parse command line arguments
GITHUB_USERNAME="$DEFAULT_GITHUB_USERNAME"
IMAGE_NAME="$DEFAULT_IMAGE_NAME"
TAG="$DEFAULT_TAG"
GITHUB_TOKEN=""
BUILD_IMAGE=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -u|--username)
            GITHUB_USERNAME="$2"
            shift 2
            ;;
        -n|--name)
            IMAGE_NAME="$2"
            shift 2
            ;;
        -t|--tag)
            TAG="$2"
            shift 2
            ;;
        --token)
            GITHUB_TOKEN="$2"
            shift 2
            ;;
        --build)
            BUILD_IMAGE=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
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

# Validate required parameters
if [ -z "$GITHUB_USERNAME" ]; then
    error "GitHub username is required. Use -u option or set GITHUB_USERNAME environment variable."
    exit 1
fi

# Use environment variable if token not provided via command line
if [ -z "$GITHUB_TOKEN" ]; then
    GITHUB_TOKEN="$GITHUB_TOKEN"
fi

if [ -z "$GITHUB_TOKEN" ]; then
    error "GitHub token is required. Use --token option or set GITHUB_TOKEN environment variable."
    error "Create a token at: https://github.com/settings/tokens"
    error "Required permissions: write:packages, read:packages"
    exit 1
fi

# Construct image names
LOCAL_IMAGE="shrk-universal:latest"
GHCR_IMAGE="ghcr.io/$GITHUB_USERNAME/$IMAGE_NAME:$TAG"

log "Configuration:"
log "  GitHub Username: $GITHUB_USERNAME"
log "  Image Name: $IMAGE_NAME"
log "  Tag: $TAG"
log "  Local Image: $LOCAL_IMAGE"
log "  GHCR Image: $GHCR_IMAGE"

cd "$PROJECT_ROOT"

# Function to run commands (with dry-run support)
run_cmd() {
    if [ "$DRY_RUN" = true ]; then
        echo "[DRY-RUN] $*"
    else
        log "Running: $*"
        "$@"
    fi
}

# Build image if requested
if [ "$BUILD_IMAGE" = true ]; then
    log "Building Docker image..."
    run_cmd docker build -f Dockerfile.universal -t "$LOCAL_IMAGE" .
fi

# Check if local image exists
if [ "$DRY_RUN" = false ] && ! docker image inspect "$LOCAL_IMAGE" >/dev/null 2>&1; then
    error "Local image '$LOCAL_IMAGE' not found. Build it first with --build option."
    exit 1
fi

# Tag image for GHCR
log "Tagging image for GHCR..."
run_cmd docker tag "$LOCAL_IMAGE" "$GHCR_IMAGE"

# Login to GHCR
log "Logging in to GitHub Container Registry..."
if [ "$DRY_RUN" = false ]; then
    echo "$GITHUB_TOKEN" | docker login ghcr.io -u "$GITHUB_USERNAME" --password-stdin
else
    echo "[DRY-RUN] echo \$GITHUB_TOKEN | docker login ghcr.io -u $GITHUB_USERNAME --password-stdin"
fi

# Push image
log "Pushing image to GHCR..."
run_cmd docker push "$GHCR_IMAGE"

if [ "$DRY_RUN" = false ]; then
    log "Successfully published to GHCR!"
    log ""
    log "Your image is now available at:"
    log "  $GHCR_IMAGE"
    log ""
    log "To use it:"
    log "  docker run --privileged -p 8080:8080 $GHCR_IMAGE"
    log ""
    log "To make it public, go to:"
    log "  https://github.com/$GITHUB_USERNAME?tab=packages"
else
    log "Dry-run completed. Use without --dry-run to actually publish."
fi
