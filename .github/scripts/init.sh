#!/bin/bash

# Universal docker init script with environment detection

set -e

SHRK_LOG_PREFIX="[SHRK-INIT]"

log() {
    echo "$SHRK_LOG_PREFIX $1"
}

error() {
    echo "$SHRK_LOG_PREFIX ERROR: $1" >&2
}

log "Starting shrk universal container..."

# Run environment detection
log "Running environment detection..."
if ! /.github/scripts/detect-env.sh; then
    error "Environment detection failed"
    exit 1
fi

# Source the environment variables set by detect-env.sh
if [ -f /usr/local/shrk-compilers/gcc ]; then
    export CC="/usr/local/shrk-compilers/gcc"
    export CXX="/usr/local/shrk-compilers/g++"
    export PATH="/usr/local/shrk-compilers:$PATH"
    log "Environment variables set for kernel module compilation"
else
    log "Warning: Custom compiler not found, using system defaults"
fi

# Test kernel module compilation capability
log "Testing kernel module compilation..."
cd "/shrk/kernel"
if make clean >/dev/null 2>&1 && make >/dev/null 2>&1; then
    log "Kernel module compilation test successful"
    make clean >/dev/null 2>&1
else
    error "Kernel module compilation test failed"
    error "This may indicate missing kernel headers or compiler issues"
    # Don't exit here - let the server start anyway for debugging
fi

# Start the server
log "Starting shrk server..."
cd "/shrk/server"
exec ./shrk_server.elf
