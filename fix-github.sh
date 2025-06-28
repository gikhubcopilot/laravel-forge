#!/bin/bash

echo "🔧 Fixing GitHub Repository Setup"
echo "================================="

# Remove the wrong remote
echo "Removing incorrect remote..."
git remote remove origin

echo ""
echo "🚨 IMPORTANT: You need to create your own GitHub repository first!"
echo ""
echo "1. Go to https://github.com/new"
echo "2. Repository name: shrk-universal"
echo "3. Make it PUBLIC (so others can use your image)"
echo "4. DON'T initialize with README (you already have files)"
echo "5. Click 'Create repository'"
echo ""

read -p "Enter your GitHub username: " GITHUB_USERNAME

if [ -z "$GITHUB_USERNAME" ]; then
    echo "❌ GitHub username is required"
    exit 1
fi

echo ""
echo "📝 Setting up repository for: $GITHUB_USERNAME"

# Add the correct remote
REPO_URL="https://github.com/$GITHUB_USERNAME/shrk-universal.git"
echo "Adding remote: $REPO_URL"
git remote add origin "$REPO_URL"

echo ""
echo "🔑 Authentication Setup:"
echo "You have two options:"
echo ""
echo "Option 1 - Personal Access Token (Recommended):"
echo "1. Go to https://github.com/settings/tokens"
echo "2. Click 'Generate new token (classic)'"
echo "3. Select: repo, write:packages, read:packages"
echo "4. Copy the token"
echo ""
echo "Option 2 - SSH Key:"
echo "1. Run: ssh-keygen -t ed25519 -C 'paymoon231@gmail.com'"
echo "2. Run: cat ~/.ssh/id_ed25519.pub"
echo "3. Add the key to https://github.com/settings/keys"
echo "4. Change remote to SSH:"
echo "   git remote set-url origin git@github.com:$GITHUB_USERNAME/shrk-universal.git"
echo ""

read -p "Which option do you prefer? (1 for Token, 2 for SSH): " AUTH_OPTION

if [ "$AUTH_OPTION" = "2" ]; then
    echo ""
    echo "🔑 Setting up SSH..."
    
    # Check if SSH key exists
    if [ ! -f ~/.ssh/id_ed25519 ]; then
        echo "Generating SSH key..."
        ssh-keygen -t ed25519 -C "paymoon231@gmail.com" -f ~/.ssh/id_ed25519 -N ""
    fi
    
    echo ""
    echo "📋 Your SSH public key (copy this to GitHub):"
    echo "=============================================="
    cat ~/.ssh/id_ed25519.pub
    echo "=============================================="
    echo ""
    echo "1. Copy the key above"
    echo "2. Go to https://github.com/settings/keys"
    echo "3. Click 'New SSH key'"
    echo "4. Paste the key and save"
    echo ""
    
    read -p "Press Enter after adding the SSH key to GitHub..."
    
    # Change to SSH remote
    git remote set-url origin "git@github.com:$GITHUB_USERNAME/shrk-universal.git"
    echo "✅ Remote changed to SSH"
    
else
    echo ""
    echo "🔑 Using Personal Access Token..."
    echo "1. Go to https://github.com/settings/tokens"
    echo "2. Generate a new token with repo and packages permissions"
    echo "3. When you push, use your username and token as password"
fi

echo ""
echo "🚀 Ready to push!"
echo "Run: git push -u origin main"
echo ""

if [ "$AUTH_OPTION" = "1" ]; then
    echo "When prompted:"
    echo "Username: $GITHUB_USERNAME"
    echo "Password: [paste your personal access token]"
fi

echo ""
echo "🎉 After successful push:"
echo "1. Go to your repository on GitHub"
echo "2. Click 'Actions' tab to see the build"
echo "3. Your image will be at: ghcr.io/$GITHUB_USERNAME/shrk-universal:latest"
echo "4. Make it public: https://github.com/$GITHUB_USERNAME?tab=packages"
