#!/usr/bin/env bash

# Legacy one-pass bootstrap used previously.
# Kept for reference.

export GITHUB_TOKEN="your_token_here"
export GITHUB_USER="jchidley"

# System update and packages
sudo apt update && sudo apt upgrade -y
sudo apt install -y git curl unzip

# Clone all repos into ~/github
mkdir -p ~/github && cd ~/github
curl -s "https://api.github.com/user/repos?per_page=100" \
  -H "Authorization: token $GITHUB_TOKEN" \
  | grep -o '"clone_url": "[^"]*"' \
  | awk -F'"' '{print $4}' \
  | sed "s|https://|https://$GITHUB_TOKEN@|" \
  | xargs -I {} git clone {}

# Apply dotfiles
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply $GITHUB_USER

# Generate SSH key
ssh-keygen -t ed25519 -C "$GITHUB_USER"
echo ""
echo "=== Add this public key to GitHub → Settings → SSH keys ==="
cat ~/.ssh/id_ed25519.pub
echo "==========================================================="
echo "Press Enter once you've added the key to GitHub..."
read

# Source bashrc (starts SSH agent and adds key)
source ~/.bashrc

# Verify SSH
ssh -T git@github.com

# Install fnm + Node
curl -fsSL https://fnm.vercel.app/install | bash
source ~/.bashrc
fnm install --lts
fnm use lts-latest

# Global npm packages
npm install -g @mariozechner/pi-coding-agent
