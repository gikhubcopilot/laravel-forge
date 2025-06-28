#!/bin/bash

# Script to build a client package with the correct compiler environment

set -e

SHRK_LOG_PREFIX="[CLIENT-BUILD]"

log() {
    echo "$SHRK_LOG_PREFIX $1"
}

error() {
    echo "$SHRK_LOG_PREFIX ERROR: $1" >&2
}

# Function to detect target system compiler
detect_target_compiler() {
    local target_proc_version="$1"
    
    log "Analyzing target system: $target_proc_version"
    
    # Extract GCC version from target system's /proc/version
    local gcc_version=""
    
    # Pattern for Ubuntu: "x86_64-linux-gnu-gcc-13 (Ubuntu 13.2.0-23ubuntu4) 13.2.0"
    gcc_version=$(echo "$target_proc_version" | grep -oP 'x86_64-linux-gnu-gcc-\K[0-9]+')
    
    if [ -z "$gcc_version" ]; then
        gcc_version=$(echo "$target_proc_version" | grep -oP 'gcc version \K[0-9]+')
    fi
    
    if [ -z "$gcc_version" ]; then
        gcc_version=$(echo "$target_proc_version" | grep -oP 'gcc \([^)]*\) \K[0-9]+')
    fi
    
    if [ -n "$gcc_version" ]; then
        log "Detected target GCC version: $gcc_version"
        echo "$gcc_version"
        return 0
    fi
    
    error "Could not detect target compiler version"
    return 1
}

# Function to setup compiler for target system
setup_target_compiler() {
    local gcc_version="$1"
    
    log "Setting up GCC-$gcc_version for target system..."
    
    # Install the target GCC version if not available
    if ! command -v "gcc-$gcc_version" >/dev/null 2>&1; then
        log "Installing GCC-$gcc_version..."
        apt-get update >/dev/null 2>&1 || true
        if ! apt-get install -y "gcc-$gcc_version" "g++-$gcc_version" 2>/dev/null; then
            error "Failed to install GCC-$gcc_version"
            return 1
        fi
    fi
    
    # Create compiler symlinks
    mkdir -p /usr/local/target-compilers
    ln -sf "$(which gcc-$gcc_version)" /usr/local/target-compilers/gcc
    ln -sf "$(which g++-$gcc_version)" /usr/local/target-compilers/g++
    
    # Create the exact compiler name that kernel expects
    cat > /usr/local/target-compilers/x86_64-linux-gnu-gcc << EOF
#!/bin/bash
exec gcc-$gcc_version "\$@"
EOF
    chmod +x /usr/local/target-compilers/x86_64-linux-gnu-gcc
    
    # Create versioned symlink
    ln -sf /usr/local/target-compilers/x86_64-linux-gnu-gcc "/usr/local/target-compilers/x86_64-linux-gnu-gcc-$gcc_version"
    
    log "Target compiler setup complete"
    return 0
}

# Function to build client package with correct compiler
build_client_package() {
    local gcc_version="$1"
    local output_dir="$2"
    
    log "Building client package with GCC-$gcc_version..."
    
    # Set up environment
    export CC="/usr/local/target-compilers/gcc"
    export CXX="/usr/local/target-compilers/g++"
    export HOSTCC="/usr/local/target-compilers/gcc"
    export PATH="/usr/local/target-compilers:$PATH"
    
    # Create output directory
    mkdir -p "$output_dir"
    
    # Copy source files
    cp -r /shrk/kernel "$output_dir/"
    cp -r /shrk/user "$output_dir/"
    
    # Create a custom install script that uses the correct compiler
    cat > "$output_dir/install.sh" << 'EOF'
#!/bin/bash

set -e

INSTALL_LOG_PREFIX="[SHRK-INSTALL]"

log() {
    echo "$INSTALL_LOG_PREFIX $1"
}

error() {
    echo "$INSTALL_LOG_PREFIX ERROR: $1" >&2
}

# Function to detect system compiler and set up environment
setup_build_environment() {
    local proc_version=$(cat /proc/version)
    log "System info: $proc_version"
    
    # Extract GCC version
    local gcc_version=""
    gcc_version=$(echo "$proc_version" | grep -oP 'x86_64-linux-gnu-gcc-\K[0-9]+')
    
    if [ -z "$gcc_version" ]; then
        gcc_version=$(echo "$proc_version" | grep -oP 'gcc version \K[0-9]+')
    fi
    
    if [ -z "$gcc_version" ]; then
        gcc_version=$(echo "$proc_version" | grep -oP 'gcc \([^)]*\) \K[0-9]+')
    fi
    
    if [ -n "$gcc_version" ]; then
        log "Detected system GCC version: $gcc_version"
        
        # Try to use the exact version
        if command -v "gcc-$gcc_version" >/dev/null 2>&1; then
            export CC="gcc-$gcc_version"
            export HOSTCC="gcc-$gcc_version"
            log "Using GCC-$gcc_version"
        else
            log "GCC-$gcc_version not available, using default gcc"
            export CC="gcc"
            export HOSTCC="gcc"
        fi
    else
        log "Could not detect GCC version, using default"
        export CC="gcc"
        export HOSTCC="gcc"
    fi
}

main() {
    log "Starting shrk installation..."
    
    # Check if running as root
    if [ "$EUID" -ne 0 ]; then
        error "Please run as root"
        exit 1
    fi
    
    # Setup build environment
    setup_build_environment
    
    # Build kernel module
    log "Building kernel module..."
    cd kernel
    if make; then
        log "Kernel module built successfully"
    else
        error "Failed to build kernel module"
        exit 1
    fi
    
    # Install kernel module
    log "Installing kernel module..."
    if insmod *.ko; then
        log "Kernel module loaded successfully"
    else
        error "Failed to load kernel module"
        exit 1
    fi
    
    # Build user client
    log "Building user client..."
    cd ../user
    if make; then
        log "User client built successfully"
    else
        error "Failed to build user client"
        exit 1
    fi
    
    # Install user client
    log "Installing user client..."
    cp shrk_client /usr/local/bin/
    chmod +x /usr/local/bin/shrk_client
    
    log "Installation completed successfully!"
    log "You can now use: shrk_client"
}

main "$@"
EOF
    
    chmod +x "$output_dir/install.sh"
    
    # Create a README for the package
    cat > "$output_dir/README.md" << EOF
# Shrk Client Package

This package contains the shrk client and kernel module compiled for your specific system.

## Installation

1. Copy this entire directory to your target system
2. Run as root: \`./install.sh\`

## Usage

After installation, use: \`shrk_client\`

## Notes

- This package was built with GCC-$gcc_version to match your kernel
- The install script will automatically detect and use the correct compiler
- Make sure you have kernel headers installed: \`apt-get install linux-headers-\$(uname -r)\`
EOF
    
    log "Client package created in $output_dir"
    return 0
}

# Main function
main() {
    local target_proc_version="$1"
    local output_dir="${2:-/tmp/shrk-client-package}"
    
    if [ -z "$target_proc_version" ]; then
        error "Usage: $0 \"<target /proc/version content>\" [output_dir]"
        error "Example: $0 \"Linux version 6.8.0-48-generic ... x86_64-linux-gnu-gcc-13 ...\""
        exit 1
    fi
    
    log "Building client package for target system..."
    
    # Detect target compiler
    local gcc_version
    if ! gcc_version=$(detect_target_compiler "$target_proc_version"); then
        exit 1
    fi
    
    # Setup target compiler
    if ! setup_target_compiler "$gcc_version"; then
        exit 1
    fi
    
    # Build client package
    if ! build_client_package "$gcc_version" "$output_dir"; then
        exit 1
    fi
    
    log "✅ Client package ready at: $output_dir"
    log "Copy this directory to your target system and run: ./install.sh"
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
