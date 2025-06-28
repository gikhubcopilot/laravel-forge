# 🚀 Universal Shrk - Automated Docker Solution

This is the **automated universal Docker solution** for the shrk rootkit that eliminates compiler version mismatch issues and automatically publishes to GitHub Container Registry.

## ⚡ Quick Start (Super Easy!)

### 1. Fork This Repository
Click "Fork" on GitHub or clone:
```bash
git clone https://github.com/yourusername/shrk-universal
cd shrk-universal
```

### 2. Push Your Code
```bash
git add .
git commit -m "Add universal shrk solution"
git push origin main
```

### 3. That's It! 🎉
- GitHub Actions automatically builds your universal Docker image
- Publishes to `ghcr.io/yourusername/shrk-universal:latest`
- Works on any Linux system without compiler issues

## 🎯 Use Your Published Image

```bash
# Anyone can now use your universal image
docker run --privileged -p 8080:8080 ghcr.io/yourusername/shrk-universal:latest
```

## 🔧 Make It Public

1. Go to `https://github.com/yourusername?tab=packages`
2. Click on `shrk-universal`
3. Change visibility to "Public"

## 📚 Documentation

- **[.github/README.md](.github/README.md)** - Complete automation guide
- **[README-Universal.md](README-Universal.md)** - Technical details about the universal solution
- **[PUBLISHING-GUIDE.md](PUBLISHING-GUIDE.md)** - Manual publishing methods

## 🎊 What You Get

- ✅ **Automatic publishing** - Just push code, get Docker image
- ✅ **Universal compatibility** - Works on Ubuntu, Debian, CentOS, etc.
- ✅ **No compiler issues** - Automatically detects and matches host compiler
- ✅ **Multi-platform** - Supports AMD64 and ARM64
- ✅ **Professional workflow** - Like major open source projects
- ✅ **Zero manual setup** - GitHub Actions handles everything

## 🔍 Problem Solved

**Before:** 
```
warning: the compiler differs from the one used to build the kernel
  The kernel was built by: x86_64-linux-gnu-gcc-13 (Ubuntu 13.2.0-23ubuntu4) 13.2.0
  You are using:           gcc-13 (Ubuntu 13.3.0-6ubuntu2~24.04) 13.3.0
```

**After:** ✅ Automatically detects and uses the correct compiler version!

---

**Ready to publish your universal shrk image?** Just push your code to GitHub! 🚀
