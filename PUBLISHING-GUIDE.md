# Publishing Shrk Universal to GitHub Container Registry (GHCR)

This guide will help you publish your universal shrk Docker image to GitHub Container Registry so others can use it like `ghcr.io/yourusername/shrk-universal`.

## Prerequisites

1. **GitHub Account** - You need a GitHub account
2. **GitHub Repository** - Fork the shrk repository or create your own
3. **Docker** - Installed on your local machine
4. **Personal Access Token** - For authentication

## Method 1: Automatic Publishing with GitHub Actions (Recommended)

### Setup Steps:

1. **Create/Fork Repository**
   ```bash
   # If forking the original shrk repo
   # Go to https://github.com/ngn13/shrk and click "Fork"
   
   # Or create a new repository and push your code
   git init
   git add .
   git commit -m "Initial commit with universal shrk solution"
   git branch -M main
   git remote add origin https://github.com/YOURUSERNAME/YOURREPO.git
   git push -u origin main
   ```

2. **Enable GitHub Actions**
   - Go to your repository on GitHub
   - Click on "Actions" tab
   - Enable GitHub Actions if not already enabled

3. **Push Your Code**
   ```bash
   git add .
   git commit -m "Add universal Docker solution"
   git push
   ```

4. **Automatic Build**
   - GitHub Actions will automatically build and publish your image
   - Check the "Actions" tab to see the build progress
   - Your image will be available at: `ghcr.io/yourusername/shrk-universal:latest`

### Making the Image Public:

1. Go to `https://github.com/YOURUSERNAME?tab=packages`
2. Find your `shrk-universal` package
3. Click on it
4. Go to "Package settings"
5. Scroll down to "Danger Zone"
6. Click "Change visibility" and select "Public"

## Method 2: Manual Publishing

### Step 1: Create Personal Access Token

1. Go to GitHub Settings: https://github.com/settings/tokens
2. Click "Generate new token" → "Generate new token (classic)"
3. Give it a name like "GHCR Publishing"
4. Select these permissions:
   - `write:packages`
   - `read:packages`
   - `delete:packages` (optional)
5. Click "Generate token"
6. **Copy the token immediately** (you won't see it again)

### Step 2: Set Environment Variables

```bash
# Set your GitHub username
export GITHUB_USERNAME="yourusername"

# Set your GitHub token (replace with your actual token)
export GITHUB_TOKEN="ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

### Step 3: Build and Publish

```bash
# Make the publish script executable
chmod +x scripts/publish-ghcr.sh

# Build and publish in one command
./scripts/publish-ghcr.sh -u $GITHUB_USERNAME --build

# Or build first, then publish
./scripts/build-universal.sh
./scripts/publish-ghcr.sh -u $GITHUB_USERNAME
```

### Step 4: Verify Publication

```bash
# Test pulling your published image
docker pull ghcr.io/yourusername/shrk-universal:latest

# Run it to test
docker run --privileged -p 8080:8080 ghcr.io/yourusername/shrk-universal:latest
```

## Publishing Script Options

The `scripts/publish-ghcr.sh` script supports various options:

```bash
# Basic usage
./scripts/publish-ghcr.sh -u yourusername --build

# Custom image name and tag
./scripts/publish-ghcr.sh -u yourusername -n my-shrk -t v1.0 --build

# Dry run (see what would happen without doing it)
./scripts/publish-ghcr.sh -u yourusername --dry-run

# Using environment variables
GITHUB_TOKEN=ghp_xxx GITHUB_USERNAME=yourusername ./scripts/publish-ghcr.sh --build
```

## Versioning Your Releases

### Using Git Tags for Versions:

```bash
# Create a version tag
git tag v1.0.0
git push origin v1.0.0

# GitHub Actions will automatically build and publish:
# - ghcr.io/yourusername/shrk-universal:v1.0.0
# - ghcr.io/yourusername/shrk-universal:v1.0
# - ghcr.io/yourusername/shrk-universal:v1
# - ghcr.io/yourusername/shrk-universal:latest
```

### Manual Version Publishing:

```bash
# Build and publish a specific version
./scripts/publish-ghcr.sh -u yourusername -t v1.0.0 --build

# Publish multiple tags
./scripts/publish-ghcr.sh -u yourusername -t v1.0.0 --build
./scripts/publish-ghcr.sh -u yourusername -t latest
```

## Using Your Published Image

Once published, anyone can use your image:

```bash
# Pull and run your universal shrk image
docker run --privileged -p 8080:8080 ghcr.io/yourusername/shrk-universal:latest

# Or with a specific version
docker run --privileged -p 8080:8080 ghcr.io/yourusername/shrk-universal:v1.0.0
```

## Troubleshooting

### Authentication Issues:

```bash
# Test login manually
echo $GITHUB_TOKEN | docker login ghcr.io -u $GITHUB_USERNAME --password-stdin
```

### Permission Issues:

- Ensure your token has `write:packages` permission
- Check that your repository allows package publishing
- Verify you're using the correct username

### Build Issues:

```bash
# Test local build first
docker build -f Dockerfile.universal -t test-image .

# Check build logs
./scripts/build-universal.sh --test
```

### Package Visibility:

- New packages are private by default
- Go to GitHub → Your Profile → Packages → Your Package → Settings
- Change visibility to public if you want others to use it

## Security Best Practices

1. **Never commit tokens to git**
2. **Use environment variables for sensitive data**
3. **Regularly rotate your personal access tokens**
4. **Use repository secrets for GitHub Actions**
5. **Review package permissions regularly**

## Example Complete Workflow

```bash
# 1. Set up environment
export GITHUB_USERNAME="yourusername"
export GITHUB_TOKEN="ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

# 2. Build and test locally
./scripts/build-universal.sh --test

# 3. Publish to GHCR
./scripts/publish-ghcr.sh -u $GITHUB_USERNAME --build

# 4. Test the published image
docker pull ghcr.io/$GITHUB_USERNAME/shrk-universal:latest
docker run --privileged -p 8080:8080 ghcr.io/$GITHUB_USERNAME/shrk-universal:latest

# 5. Make it public (via GitHub web interface)
# Go to https://github.com/yourusername?tab=packages
```

Your image will then be available for others to use just like the original `ghcr.io/ngn13/shrk`!
