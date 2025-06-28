# 🚀 Universal Shrk Usage Guide

This guide explains how to properly use your published universal shrk Docker image.

## 📦 Your Published Image

After GitHub Actions builds and publishes your image, it will be available at:
```
ghcr.io/yourusername/shrk-universal:latest
```

## 🎯 Basic Usage

### Server Mode (Recommended)
Run the shrk server for remote management:

```bash
docker run -d \
  --name shrk-server \
  --privileged \
  -v $PWD/data:/shrk/server/data \
  -p 1053:1053/udp \
  -p 7070:7070/tcp \
  -e SHRK_PASSWORD=supersecret \
  -e SHRK_PATH=/no_one_here \
  -e SHRK_HTTP_ADDR=0.0.0.0:7070 \
  -e SHRK_C2_ADDR=0.0.0.0:1053 \
  -e SHRK_HTTP_URL=http://YOUR_SERVER_IP:7070 \
  -e SHRK_C2_URL=dns://YOUR_SERVER_IP:1053 \
  ghcr.io/yourusername/shrk-universal:latest
```

### Interactive Mode
For testing and debugging:

```bash
docker run -it \
  --privileged \
  --rm \
  ghcr.io/yourusername/shrk-universal:latest \
  /bin/bash
```

## 🔧 Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `SHRK_PASSWORD` | Admin password for web interface | `supersecret` |
| `SHRK_PATH` | Hidden path for web interface | `/no_one_here` |
| `SHRK_HTTP_ADDR` | HTTP server bind address | `0.0.0.0:7070` |
| `SHRK_C2_ADDR` | C2 server bind address | `0.0.0.0:1053` |
| `SHRK_HTTP_URL` | Public HTTP URL for clients | `http://1.2.3.4:7070` |
| `SHRK_C2_URL` | Public C2 URL for clients | `dns://1.2.3.4:1053` |

## 📁 Volume Mounts

### Data Directory
Mount a local directory to persist data:
```bash
-v $PWD/data:/shrk/server/data
```

### Host Kernel Access (for kernel module compilation)
If you need kernel module functionality on the host:
```bash
-v /lib/modules:/lib/modules:ro \
-v /usr/src:/usr/src:ro \
-v /proc:/host/proc:ro
```

## 🌐 Network Configuration

### Port Mapping
- `7070/tcp` - Web interface and HTTP C2
- `1053/udp` - DNS C2 channel

### Firewall Rules
Make sure these ports are open on your server:
```bash
# Ubuntu/Debian
sudo ufw allow 7070/tcp
sudo ufw allow 1053/udp

# CentOS/RHEL
sudo firewall-cmd --permanent --add-port=7070/tcp
sudo firewall-cmd --permanent --add-port=1053/udp
sudo firewall-cmd --reload
```

## 🔍 Accessing the Web Interface

1. **Start the container** with proper environment variables
2. **Open your browser** and go to: `http://YOUR_SERVER_IP:7070/SHRK_PATH`
3. **Login** with the password you set in `SHRK_PASSWORD`

Example: `http://85.192.38.82:7070/no_one_here`

## 🛠️ Troubleshooting

### Container Logs
Check what's happening inside the container:
```bash
docker logs shrk-server
```

### Expected Log Output
```
[SHRK-DETECT] Starting environment detection...
[SHRK-DETECT] Host kernel version: Linux version 5.15.0...
[SHRK-DETECT] Detected host GCC major version: 13
[SHRK-DETECT] GCC-13 is available
[SHRK-DETECT] Compiler setup successful
[SHRK-INIT] Environment detection completed successfully
[SHRK-INIT] Warning: Kernel module compilation test failed
[SHRK-INIT] This is expected when running in a container
[SHRK-INIT] Server binary found, starting...
```

### Common Issues

#### 1. "Permission denied" errors
- Make sure you're using `--privileged` flag
- Check that ports aren't already in use

#### 2. "Server binary not found"
- The image might not have built correctly
- Check GitHub Actions build logs

#### 3. "Kernel module compilation failed"
- This is normal in containers
- The server will still work for remote management
- For kernel module functionality, you need to run on the host system

#### 4. Can't access web interface
- Check firewall settings
- Verify port mapping: `-p 7070:7070`
- Make sure you're using the correct path: `/SHRK_PATH`

## 🎯 Production Deployment

### Docker Compose Example
Create `docker-compose.yml`:

```yaml
version: '3.8'
services:
  shrk:
    image: ghcr.io/yourusername/shrk-universal:latest
    container_name: shrk-server
    privileged: true
    restart: unless-stopped
    ports:
      - "7070:7070"
      - "1053:1053/udp"
    volumes:
      - ./data:/shrk/server/data
    environment:
      - SHRK_PASSWORD=your_secure_password_here
      - SHRK_PATH=/your_hidden_path
      - SHRK_HTTP_ADDR=0.0.0.0:7070
      - SHRK_C2_ADDR=0.0.0.0:1053
      - SHRK_HTTP_URL=http://your-server-ip:7070
      - SHRK_C2_URL=dns://your-server-ip:1053
```

Run with:
```bash
docker-compose up -d
```

### Systemd Service
Create `/etc/systemd/system/shrk.service`:

```ini
[Unit]
Description=Shrk Universal Container
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/docker run -d \
  --name shrk-server \
  --privileged \
  --restart unless-stopped \
  -v /opt/shrk/data:/shrk/server/data \
  -p 7070:7070 \
  -p 1053:1053/udp \
  -e SHRK_PASSWORD=your_password \
  -e SHRK_PATH=/your_path \
  -e SHRK_HTTP_ADDR=0.0.0.0:7070 \
  -e SHRK_C2_ADDR=0.0.0.0:1053 \
  -e SHRK_HTTP_URL=http://your-ip:7070 \
  -e SHRK_C2_URL=dns://your-ip:1053 \
  ghcr.io/yourusername/shrk-universal:latest

ExecStop=/usr/bin/docker stop shrk-server
ExecStopPost=/usr/bin/docker rm shrk-server

[Install]
WantedBy=multi-user.target
```

Enable and start:
```bash
sudo systemctl enable shrk.service
sudo systemctl start shrk.service
```

## 🔒 Security Considerations

1. **Change default passwords** - Never use default credentials
2. **Use strong passwords** - Generate random passwords
3. **Restrict network access** - Use firewall rules
4. **Monitor logs** - Keep an eye on container logs
5. **Update regularly** - Pull latest image versions
6. **Use HTTPS** - Consider putting behind a reverse proxy with SSL

## 🎉 Success!

Your universal shrk container should now be running and accessible. The universal compiler detection ensures it works on any Linux system without the original compiler mismatch issues!
