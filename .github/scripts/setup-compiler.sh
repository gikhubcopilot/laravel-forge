#!/bin/bash

# Advanced compiler setup script for exact version matching

set -e

SHRK_LOG_PREFIX="[SHRK-COMPILER]"
COMPILER_SYMLINK_DIR="/usr/local/shrk-compilers"

log() {
    echo "$SHRK_LOG_PREFIX $1"
}

error() {
    echo "$SHRK_LOG_PREFIX ERROR: $1" >&2
}

# Function to extract exact compiler version from /proc/version
extract_exact_version() {
    local proc_version=$(cat /proc/version)
    log "Analyzing kernel build info: $proc_version"
    
    # Extract the exact compiler string used to build the kernel
    local compiler_info=""
    
    # Pattern for Ubuntu: "x86_64-linux-gnu-gcc-13 (Ubuntu 13.2.0-23ubuntu4) 13.2.0"
    if echo "$proc_version" | grep -q "x86_64-linux-gnu-gcc-"; then
        compiler_info=$(echo "$proc_version" | grep -oP 'x86_64-linux-gnu-gcc-[0-9]+[^)]*\)[^,]*')
        log "Found Ubuntu compiler info: $compiler_info"
        
        # Extract major version
        local major_version=$(echo "$compiler_info" | grep -oP 'x86_64-linux-gnu-gcc-\K[0-9]+')
        
        # Extract full version
        local full_version=$(echo "$compiler_info" | grep -oP '\([^)]*\) \K[0-9]+\.[0-9]+\.[0-9]+')
        
        if [ -n "$major_version" ] && [ -n "$full_version" ]; then
            log "Detected GCC major version: $major_version"
            log "Detected GCC full version: $full_version"
            echo "$major_version:$full_version"
            return 0
        fi
    fi
    
    # Fallback patterns
    local major_version=$(echo "$proc_version" | grep -oP 'gcc version \K[0-9]+' | head -1)
    if [ -z "$major_version" ]; then
        major_version=$(echo "$proc_version" | grep -oP 'gcc \([^)]*\) \K[0-9]+' | head -1)
    fi
    
    if [ -n "$major_version" ]; then
        log "Detected GCC major version (fallback): $major_version"
        echo "$major_version:"
        return 0
    fi
    
    error "Could not extract compiler version"
    return 1
}

# Function to install specific GCC version if needed
install_matching_gcc() {
    local version_info="$1"
    local major_version=$(echo "$version_info" | cut -d: -f1)
    local full_version=$(echo "$version_info" | cut -d: -f2)
    
    log "Setting up GCC-$major_version..."
    
    # Check if the exact version is available
    if command -v "gcc-$major_version" >/dev/null 2>&1; then
        log "GCC-$major_version is already available"
        return 0
    fi
    
    # Try to install it
    log "Attempting to install GCC-$major_version..."
    
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update >/dev/null 2>&1 || true
        if apt-get install -y "gcc-$major_version" "g++-$major_version" 2>/dev/null; then
            log "Successfully installed GCC-$major_version"
            return 0
        fi
    fi
    
    error "Could not install GCC-$major_version"
    return 1
}

# Function to create compiler wrapper that matches kernel build
create_compiler_wrapper() {
    local version_info="$1"
    local major_version=$(echo "$version_info" | cut -d: -f1)
    local full_version=$(echo "$version_info" | cut -d: -f2)
    
    mkdir -p "$COMPILER_SYMLINK_DIR"
    
    # Create wrapper script for GCC
    cat > "$COMPILER_SYMLINK_DIR/gcc" << EOF
#!/bin/bash
# Compiler wrapper to match kernel build environment
exec gcc-$major_version "\$@"
EOF
    
    # Create wrapper script for G++
    cat > "$COMPILER_SYMLINK_DIR/g++" << EOF
#!/bin/bash
# Compiler wrapper to match kernel build environment
exec g++-$major_version "\$@"
EOF
    
    # Create x86_64-linux-gnu-gcc symlink for kernel build system
    cat > "$COMPILER_SYMLINK_DIR/x86_64-linux-gnu-gcc" << EOF
#!/bin/bash
# Kernel build system compiler wrapper
exec gcc-$major_version "\$@"
EOF
    
    # Make all wrappers executable
    chmod +x "$COMPILER_SYMLINK_DIR/gcc"
    chmod +x "$COMPILER_SYMLINK_DIR/g++"
    chmod +x "$COMPILER_SYMLINK_DIR/x86_64-linux-gnu-gcc"
    
    # Create additional symlinks that kernel build might expect
    ln -sf "$COMPILER_SYMLINK_DIR/gcc" "$COMPILER_SYMLINK_DIR/x86_64-linux-gnu-gcc-$major_version"
    
    # Test the wrapper
    if "$COMPILER_SYMLINK_DIR/gcc" --version >/dev/null 2>&1; then
        log "Compiler wrapper created successfully"
        "$COMPILER_SYMLINK_DIR/gcc" --version | head -1
        return 0
    else
        error "Compiler wrapper test failed"
        return 1
    fi
}

# Main function
main() {
    log "Setting up exact compiler match for kernel module compilation..."
    
    # Extract version info
    local version_info
    if ! version_info=$(extract_exact_version); then
        error "Failed to extract compiler version"
        exit 1
    fi
    
    # Install matching GCC if needed
    if ! install_matching_gcc "$version_info"; then
        error "Failed to install matching GCC"
        exit 1
    fi
    
    # Create compiler wrapper
    if ! create_compiler_wrapper "$version_info"; then
        error "Failed to create compiler wrapper"
        exit 1
    fi
    
    # Export environment variables
    export CC="$COMPILER_SYMLINK_DIR/gcc"
    export CXX="$COMPILER_SYMLINK_DIR/g++"
    export HOSTCC="$COMPILER_SYMLINK_DIR/gcc"
    export PATH="$COMPILER_SYMLINK_DIR:$PATH"
    
    log "Compiler setup completed successfully"
    return 0
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
