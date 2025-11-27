#!/bin/bash
set -e

# Source credentials
if [ -f ~/gcp/credentials ]; then
    source ~/gcp/credentials
else
    echo "Error: ~/gcp/credentials file not found!"
    exit 1
fi

echo "Setting up Git..."

if [ -d "playlizt" ]; then
    echo "Directory 'playlizt' already exists. pulling latest changes..."
    cd playlizt
    git pull
else
    echo "Cloning Playlizt repository..."
    # Construct URL with token
    # Remove 'https://' if present in GITHUB_REPO_URL to avoid duplication
    CLEAN_URL=${GITHUB_REPO_URL#"https://"}
    git clone "https://${GITHUB_TOKEN}@${CLEAN_URL}" playlizt
    cd playlizt
fi

echo "Git setup complete."
