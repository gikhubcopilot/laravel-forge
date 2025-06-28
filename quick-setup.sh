#!/bin/bash

# Quick setup script for publishing shrk-universal to GHCR

set -e

log() {
    echo "[SETUP] $1"
}

error() {
    echo "[SETUP] ERROR: $1" >&2
}

log "Shrk Universal GHCR Publishing Setup"
log "===================================="

# Make scripts executable
log "Making scripts executable..."
chmod +x scripts/*.sh 2>/dev/null || {
    log "Note: You may need to run 'chmod +x scripts/*.sh' manually"
}

# Check if Docker is installed
if ! command -v docker >/dev/null 2>&1; then
    error "Docker is not installed. Please install Docker first."
    error "Visit: https://docs.docker.com/get-docker/"
    exit 1
fi

log "Docker is installed ✓"

# Check if git is installed
if ! command -v git >/dev/null 2>&1; then
    error "Git is not installed. Please install Git first."
    exit 1
fi

log "Git is installed ✓"

# Get GitHub username
echo ""
read -p "Enter your GitHub username: " GITHUB_USERNAME

if [ -z "$GITHUB_USERNAME" ]; then
    error "GitHub username is required"
    exit 1
fi

# Get GitHub token
echo ""
echo "You need a GitHub Personal Access Token with 'write:packages' permission."
echo "Create one at: https://github.com/settings/tokens"
echo ""
read -s -p "Enter your GitHub token (ghp_...): " GITHUB_TOKEN
echo ""

if [ -z "$GITHUB_TOKEN" ]; then
    error "GitHub token is required"
    exit 1
fi

# Validate token format
if [[ ! "$GITHUB_TOKEN" =~ ^ghp_ ]]; then
    log "Warning: Token doesn't start with 'ghp_' - make sure it's correct"
fi

# Create environment file
log "Creating environment configuration..."
cat > .env << EOF
# GitHub Container Registry Configuration
GITHUB_USERNAME=$GITHUB_USERNAME
GITHUB_TOKEN=$GITHUB_TOKEN
EOF

log "Environment configuration saved to .env"

# Add .env to .gitignore if not already there
if [ -f .gitignore ]; then
    if ! grep -q "^\.env$" .gitignore; then
        echo ".env" >> .gitignore
        log "Added .env to .gitignore"
    fi
else
    echo ".env" > .gitignore
    log "Created .gitignore with .env"
fi

# Test Docker build
echo ""
read -p "Do you want to test build the Docker image now? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    log "Testing Docker build..."
    if docker build -f Dockerfile.universal -t shrk-universal:test .; then
        log "Docker build test successful ✓"
        
        # Clean up test image
        docker rmi shrk-universal:test >/dev/null 2>&1 || true
    else
        error "Docker build test failed"
        exit 1
    fi
fi

# Offer to publish now
echo ""
read -p "Do you want to build and publish to GHCR now? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    log "Building and publishing to GHCR..."
    
    # Source environment variables
    export GITHUB_USERNAME="$GITHUB_USERNAME"
    export GITHUB_TOKEN="$GITHUB_TOKEN"
    
    # Run publish script
    if ./scripts/publish-ghcr.sh -u "$GITHUB_USERNAME" --build; then
        log ""
        log "🎉 Successfully published to GHCR!"
        log ""
        log "Your image is now available at:"
        log "  ghcr.io/$GITHUB_USERNAME/shrk-universal:latest"
        log ""
        log "To make it public:"
        log "1. Go to https://github.com/$GITHUB_USERNAME?tab=packages"
        log "2. Click on 'shrk-universal'"
        log "3. Go to 'Package settings'"
        log "4. Change visibility to 'Public'"
        log ""
        log "Test your published image:"
        log "  docker run --privileged -p 8080:8080 ghcr.io/$GITHUB_USERNAME/shrk-universal:latest"
    else
        error "Publishing failed. Check the error messages above."
        exit 1
    fi
else
    log ""
    log "Setup complete! To publish later, run:"
    log "  source .env"
    log "  ./scripts/publish-ghcr.sh -u \$GITHUB_USERNAME --build"
fi

log ""
log "📚 For more information, see:"
log "  - PUBLISHING-GUIDE.md (detailed publishing guide)"
log "  - README-Universal.md (universal Docker solution docs)"
log ""
log "Setup completed successfully! ✓"
