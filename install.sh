#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Update and install common packages
echo -e "Updating package lists..."
sudo apt-get update

# Install required packages
echo -e "Installing necessary packages..."
sudo apt-get install -y curl jq

# Install subfinder
if ! command_exists subfinder; then
    echo -e "Installing subfinder..."
    GO111MODULE=on go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
fi

# Install assetfinder
if ! command_exists assetfinder; then
    echo -e "Installing assetfinder..."
    go install github.com/tomnomnom/assetfinder@latest
fi

# Install amass
if ! command_exists amass; then
    echo -e "Installing amass..."
    sudo apt-get install -y amass
fi

# Install shuffledns
if ! command_exists shuffledns; then
    echo -e "Installing shuffledns..."
    go install github.com/projectdiscovery/shuffledns/cmd/shuffledns@latest
fi

# Install httpx
if ! command_exists httpx; then
    echo -e "Installing httpx..."
    go install github.com/projectdiscovery/httpx/cmd/httpx@latest
fi

# Install subzy
if ! command_exists subzy; then
    echo -e "Installing subzy..."
    go install github.com/subzy/subzy@latest
fi

# Install subjack
if ! command_exists subjack; then
    echo -e "Installing subjack..."
    go install github.com/haccer/subjack@latest
fi

echo -e "All required tools have been installed."
