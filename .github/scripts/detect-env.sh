#!/bin/bash

# Universal environment detection script for shrk
# Detects host system compiler and sets up matching build environment

set -e

SHRK_LOG_PREFIX="[SHRK-DETECT]"
COMPILER_SYMLINK_DIR="/usr/local/shrk-compilers"

log() {
    echo "$SHRK_LOG_PREFIX $1"
}

error() {
    echo "$SHRK_LOG_PREFIX ERROR: $1" >&2
}

# Function to extract compiler version from /proc/version
detect_host_compiler() {
    if [ ! -f /proc/version ]; then
        error "/proc/version not found - cannot detect host compiler"
        return 1
    fi
    
    local proc_version=$(cat /proc/version)
    log "Host kernel version: $proc_version"
    
    # Extract GCC version from /proc/version with more robust patterns
    local gcc_version=""
    
    # Pattern 1: "gcc version X.Y.Z"
    gcc_version=$(echo "$proc_version" | grep -oP 'gcc version \K[0-9]+' | head -1)
    
    # Pattern 2: "gcc (Ubuntu X.Y.Z-something) X.Y.Z"
    if [ -z "$gcc_version" ]; then
        gcc_version=$(echo "$proc_version" | grep -oP 'gcc \([^)]*\) \K[0-9]+' | head -1)
    fi
    
    # Pattern 3: Extract from Ubuntu package info
    if [ -z "$gcc_version" ]; then
        gcc_version=$(echo "$proc_version" | grep -oP 'Ubuntu [0-9]+-[0-9]+\.[0-9]+\.[0-9]+-[^)]*\) \K[0-9]+' | head -1)
    fi
    
    # Pattern 4: Extract any version number after gcc
    if [ -z "$gcc_version" ]; then
        gcc_version=$(echo "$proc_version" | grep -oP 'gcc[^0-9]*\K[0-9]+' | head -1)
    fi
    
    # Pattern 5: Look for specific Ubuntu pattern
    if [ -z "$gcc_version" ]; then
        gcc_version=$(echo "$proc_version" | sed -n 's/.*x86_64-linux-gnu-gcc-\([0-9]\+\).*/\1/p')
    fi
    
    if [ -n "$gcc_version" ]; then
        log "Detected host GCC major version: $gcc_version"
        echo "$gcc_version"
        return 0
    fi
    
    error "Could not detect GCC version from /proc/version"
    log "Proc version content: $proc_version"
    return 1
}

# Function to check if a GCC version is available
check_gcc_available() {
    local version=$1
    if command -v "gcc-$version" >/dev/null 2>&1; then
        log "GCC-$version is available"
        return 0
    fi
    return 1
}

# Function to find best available GCC version
find_best_gcc() {
    local target_version=$1
    local available_versions="14 13 12 11 10 9"
    
    # First try exact match
    if check_gcc_available "$target_version"; then
        echo "$target_version"
        return 0
    fi
    
    log "Exact GCC-$target_version not available, looking for alternatives..."
    
    # Try newer versions first, then older
    for version in $available_versions; do
        if [ "$version" -ge "$target_version" ] && check_gcc_available "$version"; then
            log "Using newer compatible GCC-$version"
            echo "$version"
            return 0
        fi
    done
    
    # If no newer version, try older versions
    for version in $(echo $available_versions | tr ' ' '\n' | sort -nr); do
        if [ "$version" -lt "$target_version" ] && check_gcc_available "$version"; then
            log "Using older compatible GCC-$version"
            echo "$version"
            return 0
        fi
    done
    
    # Fallback to default gcc
    if command -v gcc >/dev/null 2>&1; then
        log "Using default system GCC"
        echo "default"
        return 0
    fi
    
    error "No suitable GCC version found"
    return 1
}

# Function to setup compiler symlinks
setup_compiler() {
    local gcc_version=$1
    
    mkdir -p "$COMPILER_SYMLINK_DIR"
    
    if [ "$gcc_version" = "default" ]; then
        ln -sf "$(which gcc)" "$COMPILER_SYMLINK_DIR/gcc"
        ln -sf "$(which g++)" "$COMPILER_SYMLINK_DIR/g++"
    else
        ln -sf "$(which gcc-$gcc_version)" "$COMPILER_SYMLINK_DIR/gcc"
        ln -sf "$(which g++-$gcc_version)" "$COMPILER_SYMLINK_DIR/g++"
    fi
    
    # Verify symlinks work
    if "$COMPILER_SYMLINK_DIR/gcc" --version >/dev/null 2>&1; then
        log "Compiler setup successful:"
        "$COMPILER_SYMLINK_DIR/gcc" --version | head -1
        return 0
    else
        error "Compiler setup failed"
        return 1
    fi
}

# Function to detect and install missing dependencies
install_dependencies() {
    log "Checking for required dependencies..."
    
    # Check if we have kernel headers
    local kernel_version=$(uname -r)
    local headers_path="/lib/modules/$kernel_version/build"
    
    if [ ! -d "$headers_path" ]; then
        log "Kernel headers not found at $headers_path"
        log "Attempting to install kernel headers..."
        
        # Try different package managers and naming conventions
        if command -v apt-get >/dev/null 2>&1; then
            # Ubuntu/Debian
            apt-get update >/dev/null 2>&1 || true
            apt-get install -y "linux-headers-$kernel_version" 2>/dev/null || \
            apt-get install -y linux-headers-generic 2>/dev/null || \
            apt-get install -y linux-headers-$(uname -r | sed 's/[0-9]*-generic//') 2>/dev/null || \
            log "Could not install kernel headers via apt-get"
        elif command -v yum >/dev/null 2>&1; then
            # RHEL/CentOS
            yum install -y "kernel-devel-$kernel_version" 2>/dev/null || \
            yum install -y kernel-devel 2>/dev/null || \
            log "Could not install kernel headers via yum"
        elif command -v dnf >/dev/null 2>&1; then
            # Fedora
            dnf install -y "kernel-devel-$kernel_version" 2>/dev/null || \
            dnf install -y kernel-devel 2>/dev/null || \
            log "Could not install kernel headers via dnf"
        fi
        
        # Check again after installation attempt
        if [ ! -d "$headers_path" ]; then
            error "Kernel headers still not available after installation attempt"
            error "You may need to install them manually on the host system"
            return 1
        fi
    fi
    
    log "Kernel headers found at $headers_path"
    return 0
}

# Main detection function
main() {
    log "Starting environment detection..."
    
    # Detect host compiler version
    local host_gcc_version
    if ! host_gcc_version=$(detect_host_compiler); then
        log "Could not detect host compiler, using default GCC"
        host_gcc_version="13"  # Reasonable default
    fi
    
    # Find best available GCC version
    local best_gcc
    if ! best_gcc=$(find_best_gcc "$host_gcc_version"); then
        error "No suitable compiler found"
        exit 1
    fi
    
    # Setup compiler symlinks
    if ! setup_compiler "$best_gcc"; then
        error "Failed to setup compiler"
        exit 1
    fi
    
    # Install dependencies if needed
    if ! install_dependencies; then
        error "Failed to install required dependencies"
        exit 1
    fi
    
    # Export environment variables for build process
    export CC="$COMPILER_SYMLINK_DIR/gcc"
    export CXX="$COMPILER_SYMLINK_DIR/g++"
    export PATH="$COMPILER_SYMLINK_DIR:$PATH"
    
    log "Environment detection completed successfully"
    log "Using compiler: $($CC --version | head -1)"
    
    return 0
}

# Run main function if script is executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
