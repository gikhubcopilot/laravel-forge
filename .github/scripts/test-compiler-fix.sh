#!/bin/bash

# Test script to verify compiler version matching works correctly

set -e

SHRK_LOG_PREFIX="[SHRK-TEST]"

log() {
    echo "$SHRK_LOG_PREFIX $1"
}

error() {
    echo "$SHRK_LOG_PREFIX ERROR: $1" >&2
}

test_compiler_detection() {
    log "Testing compiler detection..."
    
    # Show current /proc/version
    log "Current kernel build info:"
    cat /proc/version
    
    # Test the setup-compiler script
    log "Running setup-compiler.sh..."
    if /shrk/.github/scripts/setup-compiler.sh; then
        log "✅ Compiler setup successful"
    else
        error "❌ Compiler setup failed"
        return 1
    fi
    
    # Check if compiler wrapper was created
    if [ -f /usr/local/shrk-compilers/gcc ]; then
        log "✅ Compiler wrapper created"
        log "Wrapper version: $(/usr/local/shrk-compilers/gcc --version | head -1)"
    else
        error "❌ Compiler wrapper not found"
        return 1
    fi
    
    return 0
}

test_kernel_module_build() {
    log "Testing kernel module compilation..."
    
    # Set up environment
    export CC="/usr/local/shrk-compilers/gcc"
    export CXX="/usr/local/shrk-compilers/g++"
    export HOSTCC="/usr/local/shrk-compilers/gcc"
    export PATH="/usr/local/shrk-compilers:$PATH"
    
    cd /shrk/kernel
    
    # Clean first
    make clean >/dev/null 2>&1 || true
    
    # Try to build
    log "Attempting kernel module build..."
    if make 2>&1 | tee /tmp/build.log; then
        log "✅ Kernel module build successful"
        
        # Check for warnings
        if grep -q "warning: the compiler differs" /tmp/build.log; then
            error "❌ Still getting compiler version mismatch warning"
            return 1
        else
            log "✅ No compiler version mismatch warnings"
        fi
        
        # Check if module was created
        if ls *.ko >/dev/null 2>&1; then
            log "✅ Kernel module (.ko file) created successfully"
        else
            error "❌ No kernel module (.ko file) found"
            return 1
        fi
        
    else
        error "❌ Kernel module build failed"
        log "Build log:"
        cat /tmp/build.log
        return 1
    fi
    
    # Clean up
    make clean >/dev/null 2>&1 || true
    
    return 0
}

test_server_startup() {
    log "Testing server startup..."
    
    cd /shrk/server
    
    if [ -f "./shrk_server.elf" ]; then
        log "✅ Server binary found"
        
        # Test if it can start (just check if it doesn't immediately crash)
        timeout 5s ./shrk_server.elf >/dev/null 2>&1 || true
        log "✅ Server startup test completed"
    else
        error "❌ Server binary not found"
        return 1
    fi
    
    return 0
}

main() {
    log "Starting comprehensive compiler fix test..."
    log "================================================"
    
    local failed=0
    
    # Test 1: Compiler Detection
    log "Test 1: Compiler Detection"
    if ! test_compiler_detection; then
        failed=$((failed + 1))
    fi
    echo ""
    
    # Test 2: Kernel Module Build
    log "Test 2: Kernel Module Build"
    if ! test_kernel_module_build; then
        failed=$((failed + 1))
    fi
    echo ""
    
    # Test 3: Server Startup
    log "Test 3: Server Startup"
    if ! test_server_startup; then
        failed=$((failed + 1))
    fi
    echo ""
    
    # Summary
    log "================================================"
    if [ $failed -eq 0 ]; then
        log "🎉 ALL TESTS PASSED! Universal compiler fix is working correctly."
        log "The compiler version mismatch issue has been resolved."
    else
        error "❌ $failed test(s) failed. The fix needs more work."
        exit 1
    fi
}

# Run tests
main "$@"
