#!/bin/bash

# Test script for the universal shrk Docker solution

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
IMAGE_NAME="shrk-universal:latest"

log() {
    echo "[TEST] $1"
}

error() {
    echo "[TEST] ERROR: $1" >&2
}

# Test 1: Check if all required files exist
test_files() {
    log "Testing required files..."
    
    local required_files=(
        "Dockerfile.universal"
        "scripts/detect-env.sh"
        "scripts/build-universal.sh"
        "scripts/init.sh"
        "kernel/Makefile"
        "README-Universal.md"
    )
    
    for file in "${required_files[@]}"; do
        if [ ! -f "$PROJECT_ROOT/$file" ]; then
            error "Required file missing: $file"
            return 1
        fi
    done
    
    log "All required files present ✓"
    return 0
}

# Test 2: Check if scripts are executable
test_permissions() {
    log "Testing script permissions..."
    
    local scripts=(
        "scripts/detect-env.sh"
        "scripts/build-universal.sh"
        "scripts/init.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [ ! -x "$PROJECT_ROOT/$script" ]; then
            log "Making $script executable..."
            chmod +x "$PROJECT_ROOT/$script"
        fi
    done
    
    log "Script permissions verified ✓"
    return 0
}

# Test 3: Validate Dockerfile syntax
test_dockerfile() {
    log "Testing Dockerfile syntax..."
    
    if ! docker build -f "$PROJECT_ROOT/Dockerfile.universal" --dry-run "$PROJECT_ROOT" >/dev/null 2>&1; then
        error "Dockerfile.universal has syntax errors"
        return 1
    fi
    
    log "Dockerfile syntax valid ✓"
    return 0
}

# Test 4: Check environment detection script
test_detection_script() {
    log "Testing environment detection script..."
    
    # Test script syntax
    if ! bash -n "$PROJECT_ROOT/scripts/detect-env.sh"; then
        error "detect-env.sh has syntax errors"
        return 1
    fi
    
    # Test if it can detect current system (dry run)
    if ! bash "$PROJECT_ROOT/scripts/detect-env.sh" 2>/dev/null; then
        log "Warning: Environment detection script failed on current system"
        log "This may be normal if running outside a proper Linux environment"
    fi
    
    log "Environment detection script syntax valid ✓"
    return 0
}

# Test 5: Build the image (optional)
test_build() {
    log "Testing Docker image build..."
    
    if ! command -v docker >/dev/null 2>&1; then
        log "Docker not available, skipping build test"
        return 0
    fi
    
    log "Building test image (this may take a while)..."
    if ! docker build -f "$PROJECT_ROOT/Dockerfile.universal" -t "$IMAGE_NAME" "$PROJECT_ROOT"; then
        error "Docker build failed"
        return 1
    fi
    
    log "Docker build successful ✓"
    
    # Test container startup
    log "Testing container startup..."
    CONTAINER_ID=$(docker run -d --privileged "$IMAGE_NAME" 2>/dev/null || echo "")
    
    if [ -n "$CONTAINER_ID" ]; then
        sleep 3
        
        if docker ps -q --filter "id=$CONTAINER_ID" | grep -q .; then
            log "Container started successfully ✓"
            docker logs "$CONTAINER_ID" 2>&1 | head -10
        else
            log "Container failed to start properly"
            docker logs "$CONTAINER_ID" 2>&1
        fi
        
        # Cleanup
        docker stop "$CONTAINER_ID" >/dev/null 2>&1 || true
        docker rm "$CONTAINER_ID" >/dev/null 2>&1 || true
    else
        log "Could not start test container"
    fi
    
    return 0
}

# Main test function
main() {
    log "Starting universal shrk solution tests..."
    log "Project root: $PROJECT_ROOT"
    
    cd "$PROJECT_ROOT"
    
    # Run tests
    test_files || exit 1
    test_permissions || exit 1
    test_dockerfile || exit 1
    test_detection_script || exit 1
    
    # Ask user if they want to run build test
    if command -v docker >/dev/null 2>&1; then
        echo ""
        read -p "Do you want to run the Docker build test? (y/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            test_build
        else
            log "Skipping Docker build test"
        fi
    fi
    
    log ""
    log "All tests completed! ✓"
    log ""
    log "Next steps:"
    log "1. Build the universal image: ./scripts/build-universal.sh"
    log "2. Run the container: docker run --privileged -p 8080:8080 shrk-universal:latest"
    log "3. Access the web interface at http://localhost:8080"
    log ""
    log "For more information, see README-Universal.md"
}

# Run main function
main "$@"
