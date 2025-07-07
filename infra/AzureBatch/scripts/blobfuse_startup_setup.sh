#!/bin/bash

# Download the Microsoft packages configuration
sudo wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb

# Install the downloaded package
sudo dpkg -i packages-microsoft-prod.deb

# Update the package list
sudo apt-get update

# Install required dependencies
sudo apt-get install -y libfuse3-dev fuse3

# Install blobfuse2
sudo apt-get install -y blobfuse2

# Create the mount point directory
sudo mkdir -p /landing
sudo mkdir -p /blobfuse/cache/landing

sudo mkdir -p /annotated
sudo mkdir -p /blobfuse/cache/annotated

sudo mkdir -p /extracted
sudo mkdir -p /blobfuse/cache/extracted


# Unmount other specified mount points
sudo blobfuse2 unmount /landing || echo "Warning: Failed to unmount /landing, continuing..."
sudo blobfuse2 unmount /annotated || echo "Warning: Failed to unmount /rosbag, continuing..."
sudo blobfuse2 unmount /extracted || echo "Warning: Failed to unmount /extracted, continuing..."


# Mount the Blobfuse2 file system
sudo blobfuse2 mount /landing --config-file=blobfuse_config_landing.yaml --allow-other --use-adls=true --block-cache-prefetch-on-open=true
sudo blobfuse2 mount /annotated --config-file=blobfuse_config_rosbag.yaml --allow-other --use-adls=true --block-cache-prefetch-on-open=true
sudo blobfuse2 mount /extracted --config-file=blobfuse_config_extracted.yaml --allow-other --use-adls=true --block-cache-prefetch-on-open=true