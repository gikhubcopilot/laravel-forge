# Shrk Universal Docker Solution

This document describes the universal Docker solution for the shrk rootkit that automatically adapts to any Linux system, eliminating compiler version mismatch issues.

## Problem Solved

The original shrk Docker image (`ghcr.io/ngn13/shrk`) uses Alpine Linux and may have compiler version mismatches when running on different host systems. This causes errors like:

```
warning: the compiler differs from the one used to build the kernel
  The kernel was built by: x86_64-linux-gnu-gcc-13 (Ubuntu 13.2.0-23ubuntu4) 13.2.0
  You are using:           gcc-13 (Ubuntu 13.3.0-6ubuntu2~24.04) 13.3.0
```

## Universal Solution

The universal Docker solution automatically:

1. **Detects the host system's kernel compiler** from `/proc/version`
2. **Installs matching GCC versions** (9, 10, 11, 12, 13, 14)
3. **Sets up the correct build environment** for kernel module compilation
4. **Falls back gracefully** to compatible compiler versions
5. **Works across different Linux distributions** (Ubuntu, Debian, CentOS, RHEL, etc.)

## Files Created/Modified

### New Files
- `Dockerfile.universal` - Universal Docker image definition
- `scripts/detect-env.sh` - Environment detection script
- `scripts/build-universal.sh` - Build script for the universal image
- `README-Universal.md` - This documentation

### Modified Files
- `scripts/init.sh` - Enhanced with environment detection
- `kernel/Makefile` - Updated to use detected compiler

## Quick Start

### 1. Build the Universal Image

```bash
# Make the build script executable
chmod +x scripts/build-universal.sh

# Build the image
./scripts/build-universal.sh

# Or build with testing
./scripts/build-universal.sh --test
```

### 2. Run the Universal Container

```bash
# Basic run
docker run --privileged -p 8080:8080 shrk-universal:latest

# Production run (detached with restart policy)
docker run -d --privileged --restart unless-stopped -p 8080:8080 shrk-universal:latest

# Run with custom name
docker run -d --name shrk-rootkit --privileged -p 8080:8080 shrk-universal:latest
```

### 3. Access the Web Interface

Open your browser and navigate to `http://your-server-ip:8080`

## How It Works

### Environment Detection Process

1. **Kernel Analysis**: Reads `/proc/version` to extract the compiler used to build the host kernel
2. **Compiler Matching**: Finds the best available GCC version that matches or is compatible
3. **Symlink Setup**: Creates symlinks in `/usr/local/shrk-compilers/` pointing to the correct compiler
4. **Dependency Check**: Verifies kernel headers are available and installs if needed
5. **Build Test**: Tests kernel module compilation before starting the server

### Supported Systems

The universal solution has been designed to work on:

- **Ubuntu**: 18.04, 20.04, 22.04, 24.04
- **Debian**: 10, 11, 12
- **CentOS**: 7, 8, 9
- **RHEL**: 7, 8, 9
- **Fedora**: Recent versions
- **Other**: Most modern Linux distributions

### Compiler Compatibility

The image includes GCC versions:
- GCC 9, 10, 11, 12, 13, 14
- Automatic fallback to compatible versions
- Support for cross-compilation scenarios

## Build Options

### Build Script Usage

```bash
./scripts/build-universal.sh [OPTIONS]

Options:
  -t, --tag TAG     Set image tag (default: latest)
  -n, --name NAME   Set image name (default: shrk-universal)
  --no-cache        Build without using cache
  --test            Run test after build
  -h, --help        Show this help message
```

### Examples

```bash
# Build with custom tag
./scripts/build-universal.sh -t v2.0

# Build without cache and test
./scripts/build-universal.sh --no-cache --test

# Build with custom name and tag
./scripts/build-universal.sh -n my-shrk -t production
```

## Manual Docker Build

If you prefer to build manually:

```bash
# Build the image
docker build -f Dockerfile.universal -t shrk-universal:latest .

# Run the container
docker run --privileged -p 8080:8080 shrk-universal:latest
```

## Troubleshooting

### Container Logs

Check the container logs to see the environment detection process:

```bash
docker logs <container-id>
```

Look for messages like:
```
[SHRK-DETECT] Starting environment detection...
[SHRK-DETECT] Host kernel version: Linux version 5.15.0-91-generic ...
[SHRK-DETECT] Detected host GCC major version: 13
[SHRK-DETECT] GCC-13 is available
[SHRK-DETECT] Compiler setup successful:
[SHRK-INIT] Environment detection completed successfully
[SHRK-INIT] Kernel module compilation test successful
```

### Common Issues

#### 1. Kernel Headers Missing
```
[SHRK-DETECT] ERROR: Kernel headers still not available after installation attempt
```

**Solution**: Install kernel headers on the host system:
```bash
# Ubuntu/Debian
sudo apt-get install linux-headers-$(uname -r)

# CentOS/RHEL
sudo yum install kernel-devel-$(uname -r)
```

#### 2. No Suitable Compiler Found
```
[SHRK-DETECT] ERROR: No suitable GCC version found
```

**Solution**: The container should include multiple GCC versions. If this error occurs, check if the container was built correctly.

#### 3. Compilation Test Failed
```
[SHRK-INIT] ERROR: Kernel module compilation test failed
```

**Solution**: This usually indicates missing kernel headers or incompatible compiler. Check the detailed error messages in the logs.

### Debug Mode

To run the container in debug mode:

```bash
# Run with shell access
docker run -it --privileged shrk-universal:latest /bin/bash

# Manually run detection
/shrk/scripts/detect-env.sh

# Test compilation
cd /shrk/kernel && make clean && make
```

## Security Considerations

### Privileged Mode Required

The container requires `--privileged` mode to:
- Access kernel modules and headers
- Load kernel modules
- Access system information from `/proc`

### Network Exposure

The web interface runs on port 8080. In production:
- Use a reverse proxy with SSL/TLS
- Implement proper authentication
- Restrict network access as needed

## Comparison with Original

| Feature | Original Image | Universal Image |
|---------|---------------|-----------------|
| Base OS | Alpine Linux | Ubuntu 24.04 |
| Compiler | Single GCC version | Multiple GCC versions (9-14) |
| Compatibility | Limited | Universal |
| Auto-detection | No | Yes |
| Fallback support | No | Yes |
| Size | Smaller | Larger (but more compatible) |

## Contributing

To improve the universal solution:

1. Test on additional Linux distributions
2. Add support for more compiler versions
3. Improve error handling and logging
4. Optimize image size while maintaining compatibility

## License

Same as the original shrk project.
