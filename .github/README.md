# Automated Universal Shrk Docker Publishing

This directory contains the automated solution for building and publishing the universal shrk Docker image to GitHub Container Registry (GHCR).

## 🚀 How It Works

Simply push your code to GitHub and the automation takes care of everything:

1. **Push to GitHub** → Triggers automatic build
2. **GitHub Actions** → Builds universal Docker image
3. **GHCR Publishing** → Automatically publishes to `ghcr.io/yourusername/shrk-universal`
4. **Ready to Use** → Anyone can pull and run your image

## 📁 Files Structure

```
.github/
├── workflows/
│   └── build-and-publish.yml    # Main automation workflow
├── scripts/
│   ├── detect-env.sh           # Environment detection
│   ├── init.sh                 # Container initialization
│   └── build-universal.sh      # Local build script
└── README.md                   # This file
```

## ⚡ Quick Setup

### 1. Fork or Create Repository
```bash
# Fork the original shrk repo or create new one
git clone https://github.com/yourusername/shrk-universal
cd shrk-universal
```

### 2. Push Your Code
```bash
git add .
git commit -m "Add universal shrk solution"
git push origin main
```

### 3. Watch the Magic ✨
- Go to your repository on GitHub
- Click "Actions" tab
- Watch the build process
- Your image will be published automatically!

## 📦 Published Image

After successful build, your image will be available at:
```
ghcr.io/yourusername/shrk-universal:latest
```

## 🎯 Usage

Anyone can now use your universal image:
```bash
# Pull and run
docker run --privileged -p 8080:8080 ghcr.io/yourusername/shrk-universal:latest

# Or with specific version
docker run --privileged -p 8080:8080 ghcr.io/yourusername/shrk-universal:v1.0.0
```

## 🏷️ Versioning

Create version tags for releases:
```bash
git tag v1.0.0
git push origin v1.0.0
```

This automatically creates:
- `ghcr.io/yourusername/shrk-universal:v1.0.0`
- `ghcr.io/yourusername/shrk-universal:v1.0`
- `ghcr.io/yourusername/shrk-universal:v1`
- `ghcr.io/yourusername/shrk-universal:latest`

## 🔧 Making Image Public

1. Go to `https://github.com/yourusername?tab=packages`
2. Click on `shrk-universal`
3. Go to "Package settings"
4. Change visibility to "Public"

## 🛠️ Local Development

For local testing:
```bash
# Build locally
./.github/scripts/build-universal.sh --test

# Test the image
docker run --privileged -p 8080:8080 shrk-universal:latest
```

## 🔍 What Makes It Universal

The automation includes:
- **Multi-compiler support** (GCC 9-14)
- **Automatic host detection** from `/proc/version`
- **Cross-platform builds** (AMD64 + ARM64)
- **Fallback mechanisms** for compatibility
- **Works on all Linux distros** (Ubuntu, Debian, CentOS, etc.)

## 🎉 Benefits

- ✅ **Zero manual setup** - just push and go
- ✅ **Automatic publishing** - no manual Docker commands
- ✅ **Version management** - automatic tagging
- ✅ **Multi-platform** - works on different architectures
- ✅ **Universal compatibility** - solves compiler mismatch issues
- ✅ **Professional workflow** - like major open source projects

## 🔒 Security

- Uses GitHub's built-in `GITHUB_TOKEN`
- No manual credential management
- Secure by default
- Follows GitHub best practices

---

**That's it!** 🎊 Your universal shrk image will be automatically built and published every time you push code. No more manual Docker builds or compiler version headaches!
