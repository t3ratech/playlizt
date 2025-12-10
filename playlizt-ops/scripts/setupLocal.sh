#!/bin/bash
set -e

echo "Setting up Local Environment..."

# Cleanup potential broken Google Cloud repo configurations immediately to prevent apt update failures
sudo rm -f /etc/apt/sources.list.d/google-cloud-sdk.list
sudo rm -f /usr/share/keyrings/cloud.google.gpg
sudo rm -f /etc/apt/trusted.gpg.d/google-cloud-sdk.gpg

# Update packages
sudo apt-get update || true

# Install basic tools
sudo apt-get install -y curl wget git unzip zip software-properties-common apt-transport-https ca-certificates gnupg lsb-release

# Install Java (Temurin 21)
if ! command -v java &> /dev/null; then
    echo "Installing Java..."
    sudo mkdir -p /etc/apt/keyrings
    wget -O - https://packages.adoptium.net/artifactory/api/gpg/key/public | sudo tee /etc/apt/keyrings/adoptium.asc
    echo "deb [signed-by=/etc/apt/keyrings/adoptium.asc] https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | sudo tee /etc/apt/sources.list.d/adoptium.list
    sudo apt-get update
    sudo apt-get install -y temurin-25-jdk
else
    echo "Java already installed."
fi

# Install Docker
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    echo "Docker installed. You may need to log out and back in."
else
    echo "Docker already installed."
fi

# Install Terraform
if ! command -v terraform &> /dev/null; then
    echo "Installing Terraform..."
    wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor --yes -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    # Update apt (allow partial failure)
    sudo apt-get update || true
    sudo apt-get install -y terraform
else
    echo "Terraform already installed."
fi

# Install Google Cloud SDK (via Snap to avoid apt key issues)
if ! command -v gcloud &> /dev/null; then
    echo "Installing Google Cloud SDK via Snap..."
    # Clean up apt attempts
    sudo rm -f /etc/apt/sources.list.d/google-cloud-sdk.list
    sudo rm -f /usr/share/keyrings/cloud.google.gpg
    sudo rm -f /etc/apt/trusted.gpg.d/google-cloud-sdk.gpg
    
    # Install via Snap
    sudo snap install google-cloud-cli --classic
else
    echo "Google Cloud SDK already installed."
fi

# Install Android SDK
if [ ! -d "/opt/android/sdk" ]; then
    echo "Installing Android SDK..."
    mkdir -p "/opt/android/sdk"
    cd "/opt/android/sdk"
    wget https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -o cmdline-tools.zip
    unzip -q cmdline-tools.zip
    
    # Reorganize for cmdline-tools/latest structure
    mkdir -p cmdline-tools/latest
    mv cmdline-tools/* cmdline-tools/latest/ 2>/dev/null || true
    # The previous mv might have moved 'latest' into itself if we are not careful, but since 'latest' was empty it should be fine.
    # Actually cmdline-tools zip extracts a folder 'cmdline-tools'.
    # So we have /opt/android/sdk/cmdline-tools (folder) and /opt/android/sdk/cmdline-tools.zip
    # We want /opt/android/sdk/cmdline-tools/latest/bin
    
    # Correct approach:
    # 1. Unzip -> creates 'cmdline-tools' folder in current dir (/opt/android/sdk)
    # 2. Rename 'cmdline-tools' to 'latest'
    # 3. Create 'cmdline-tools' parent folder
    # 4. Move 'latest' into 'cmdline-tools'
    
    rm -rf cmdline-tools # cleanup if partial
    unzip -q cmdline-tools.zip
    mv cmdline-tools latest
    mkdir cmdline-tools
    mv latest cmdline-tools/
    
    rm cmdline-tools.zip
    
    # Add to PATH
    echo 'export ANDROID_HOME=/opt/android/sdk' >> ~/.bashrc
    echo 'export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools' >> ~/.bashrc
else
    echo "Android SDK appears to be present."
fi

echo "Local setup complete."
