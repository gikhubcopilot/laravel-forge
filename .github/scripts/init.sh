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
if ! /shrk/.github/scripts/detect-env.sh; then
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
    log "Warning: Kernel module compilation test failed"
    log "This is expected when running in a container without proper kernel headers"
    log "The server will still start and work for remote management"
fi

# Start the server
log "Starting shrk server..."
cd "/shrk/server"

# Check if server binary exists
if [ ! -f "./shrk_server.elf" ]; then
    error "Server binary not found at /shrk/server/shrk_server.elf"
    exit 1
fi

log "Server binary found, starting..."
exec ./shrk_server.elf
