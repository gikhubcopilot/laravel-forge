# 🎯 Shrk Client Package Solution

This solves the compiler mismatch issue when installing shrk client on different servers.

## 🔍 The Problem

You're running:
1. **Server**: Docker container with shrk server
2. **Client**: Different server where you want to install the shrk client

When you run the client installer, it downloads and compiles with a different compiler version, causing the mismatch error.

## ✅ The Solution

Build a **client package** from your Docker container that matches your target server's compiler.

## 🚀 Step-by-Step Instructions

### Step 1: Get Your Target Server Info

On your **client server** (where you want to install shrk), run:
```bash
cat /proc/version
```

Copy the entire output. It should look like:
```
Linux version 6.8.0-48-generic (buildd@lcy02-amd64-080) (x86_64-linux-gnu-gcc-13 (Ubuntu 13.2.0-23ubuntu4) 13.2.0, GNU ld (GNU Binutils for Ubuntu) 2.42) #54-Ubuntu SMP PREEMPT_DYNAMIC Fri Aug 30 10:18:31 UTC 2024
```

### Step 2: Build Client Package in Docker

Run your Docker container interactively:
```bash
docker run -it --privileged ghcr.io/yourusername/shrk-universal:latest /bin/bash
```

Inside the container, build the client package:
```bash
# Replace the quoted text with your actual /proc/version output
/shrk/.github/scripts/build-client-package.sh "Linux version 6.8.0-48-generic (buildd@lcy02-amd64-080) (x86_64-linux-gnu-gcc-13 (Ubuntu 13.2.0-23ubuntu4) 13.2.0, GNU ld (GNU Binutils for Ubuntu) 2.42) #54-Ubuntu SMP PREEMPT_DYNAMIC Fri Aug 30 10:18:31 UTC 2024"
```

### Step 3: Copy Package to Host

From another terminal (outside Docker), copy the package:
```bash
# Get container ID
CONTAINER_ID=$(docker ps -q --filter ancestor=ghcr.io/yourusername/shrk-universal:latest)

# Copy package to host
docker cp $CONTAINER_ID:/tmp/shrk-client-package ./shrk-client-package
```

### Step 4: Transfer to Target Server

Copy the package to your target server:
```bash
# Using scp
scp -r ./shrk-client-package root@your-target-server:/tmp/

# Or using rsync
rsync -av ./shrk-client-package/ root@your-target-server:/tmp/shrk-client-package/
```

### Step 5: Install on Target Server

On your **target server**:
```bash
cd /tmp/shrk-client-package
chmod +x install.sh
./install.sh
```

## 🎉 Expected Result

Instead of the compiler mismatch error, you should see:
```
[SHRK-INSTALL] Starting shrk installation...
[SHRK-INSTALL] System info: Linux version 6.8.0-48-generic...
[SHRK-INSTALL] Detected system GCC version: 13
[SHRK-INSTALL] Using GCC-13
[SHRK-INSTALL] Building kernel module...
[SHRK-INSTALL] Kernel module built successfully
[SHRK-INSTALL] Kernel module loaded successfully
[SHRK-INSTALL] Building user client...
[SHRK-INSTALL] User client built successfully
[SHRK-INSTALL] Installing user client...
[SHRK-INSTALL] Installation completed successfully!
[SHRK-INSTALL] You can now use: shrk_client
```

## 🛠️ Alternative: One-Line Solution

If you want to automate this, create a script on your server:

```bash
#!/bin/bash
# save as build-and-install-client.sh

TARGET_PROC_VERSION=$(cat /proc/version)
DOCKER_IMAGE="ghcr.io/yourusername/shrk-universal:latest"

echo "Building client package for this system..."

# Run Docker container and build package
docker run --rm -v $PWD:/output --privileged $DOCKER_IMAGE bash -c "
/shrk/.github/scripts/build-client-package.sh '$TARGET_PROC_VERSION' /output/shrk-client-package
"

echo "Installing client package..."
cd shrk-client-package
chmod +x install.sh
./install.sh

echo "Done! Client installed successfully."
```

Then just run:
```bash
chmod +x build-and-install-client.sh
./build-and-install-client.sh
```

## 🔧 Troubleshooting

### If you get "GCC-X not available":
```bash
# Install the required GCC version on target server
apt-get update
apt-get install gcc-13 g++-13  # Replace 13 with your version
```

### If you get "kernel headers not found":
```bash
# Install kernel headers on target server
apt-get install linux-headers-$(uname -r)
```

## 🎯 Why This Works

1. **Exact Compiler Match**: The package is built with the same GCC version as your target kernel
2. **Smart Detection**: The install script automatically detects and uses the correct compiler
3. **No Version Mismatch**: Eliminates the compiler version warning completely
4. **Universal**: Works on any Linux distribution and kernel version

This solution ensures your shrk client compiles and installs without any compiler version mismatch issues!
