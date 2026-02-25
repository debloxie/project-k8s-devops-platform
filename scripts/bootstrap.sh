#!/usr/bin/env bash
set -euo pipefail

# Update system
apt-get update -y
apt-get upgrade -y

# Install Docker
apt-get install -y \
  ca-certificates \
  curl \
  gnupg \
  lsb-release

mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io

usermod -aG docker ubuntu || true

# Install MicroK8s
snap install microk8s --classic --channel=1.28/stable

# Add ubuntu user to microk8s group and configure kubectl
usermod -aG microk8s ubuntu
mkdir -p /home/ubuntu/.kube
microk8s config > /home/ubuntu/.kube/config
chown -R ubuntu:ubuntu /home/ubuntu/.kube

# Enable lightweight add-ons
microk8s enable dns
microk8s enable storage
microk8s enable prometheus

echo "MicroK8s + Prometheus installed successfully."
