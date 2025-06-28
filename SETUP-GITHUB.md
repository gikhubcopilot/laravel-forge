# 🚀 GitHub Setup Guide for Universal Shrk

You're getting authentication errors because of credential issues. Here's how to fix it:

## 🔧 Fix Authentication Issues

### Method 1: Use Personal Access Token (Recommended)

1. **Create a Personal Access Token:**
   - Go to https://github.com/settings/tokens
   - Click "Generate new token" → "Generate new token (classic)"
   - Give it a name like "Shrk Universal"
   - Select these permissions:
     - `repo` (Full control of private repositories)
     - `write:packages` (Upload packages to GitHub Package Registry)
     - `read:packages` (Download packages from GitHub Package Registry)
   - Click "Generate token"
   - **Copy the token immediately** (you won't see it again)

2. **Use Token for Authentication:**
   ```bash
   # Remove the problematic remote
   git remote remove origin
   
   # Add remote with your actual username and repository
   git remote add origin https://github.com/YOURUSERNAME/YOURREPO.git
   
   # Push using token (replace with your actual token)
   git push -u origin main
   # When prompted for username: enter your GitHub username
   # When prompted for password: paste your personal access token
   ```

### Method 2: Use SSH (Alternative)

1. **Generate SSH Key:**
   ```bash
   ssh-keygen -t ed25519 -C "paymoon231@gmail.com"
   # Press Enter for default location
   # Press Enter for no passphrase (or set one if you prefer)
   ```

2. **Add SSH Key to GitHub:**
   ```bash
   # Copy your public key
   cat ~/.ssh/id_ed25519.pub
   ```
   - Go to https://github.com/settings/keys
   - Click "New SSH key"
   - Paste your public key
   - Click "Add SSH key"

3. **Use SSH Remote:**
   ```bash
   git remote remove origin
   git remote add origin git@github.com:YOURUSERNAME/YOURREPO.git
   git push -u origin main
   ```

## 📁 Create Your Repository

1. **Go to GitHub and create a new repository:**
   - Repository name: `shrk-universal` (or any name you prefer)
   - Make it public if you want others to use it
   - Don't initialize with README (you already have files)

2. **Update your remote URL:**
   ```bash
   git remote remove origin
   git remote add origin https://github.com/YOURUSERNAME/shrk-universal.git
   # or with SSH:
   git remote add origin git@github.com:YOURUSERNAME/shrk-universal.git
   ```

## 🎯 Complete Setup Commands

```bash
# 1. Fix git config (use your actual email)
git config --global user.name "Your Name"
git config --global user.email "paymoon231@gmail.com"

# 2. Remove old remote and add correct one
git remote remove origin
git remote add origin https://github.com/YOURUSERNAME/shrk-universal.git

# 3. Push with authentication
git push -u origin main
# Enter your GitHub username when prompted
# Enter your personal access token as password
```

## 🔍 Verify Everything Works

After successful push:

1. **Check GitHub Actions:**
   - Go to your repository on GitHub
   - Click "Actions" tab
   - You should see the build running

2. **Check Package Registry:**
   - After build completes, go to `https://github.com/YOURUSERNAME?tab=packages`
   - You should see `shrk-universal` package

3. **Test Your Image:**
   ```bash
   docker pull ghcr.io/YOURUSERNAME/shrk-universal:latest
   docker run --privileged -p 8080:8080 ghcr.io/YOURUSERNAME/shrk-universal:latest
   ```

## 🎉 Make It Public

1. Go to `https://github.com/YOURUSERNAME?tab=packages`
2. Click on `shrk-universal`
3. Go to "Package settings"
4. Change visibility to "Public"

## 🚨 Troubleshooting

### If you still get permission errors:
```bash
# Clear all git credentials
git config --global --unset credential.helper
rm -f ~/.git-credentials

# Try again with fresh credentials
git push -u origin main
```

### If repository doesn't exist:
- Make sure you created the repository on GitHub first
- Use the exact repository name in your remote URL
- Make sure the repository belongs to your account

---

**Once this is set up, your universal shrk image will be automatically built and published every time you push code!** 🚀
