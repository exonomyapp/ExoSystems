#!/bin/bash

# ExoTalk Daemon Setup Script
# This script installs the signaling server and zrok relay as systemd services.

set -e

# 1. Copy service files to /etc/systemd/system/
sudo cp exotalk-signaling.service /etc/systemd/system/
sudo cp exotalk-zrok.service /etc/systemd/system/

# 2. Reload systemd
sudo systemctl daemon-reload

# 3. Enable services to start on boot
sudo systemctl enable exotalk-signaling.service
sudo systemctl enable exotalk-zrok.service

# 4. Start services now
sudo systemctl start exotalk-signaling.service
sudo systemctl start exotalk-zrok.service

echo "------------------------------------------------"
echo "ExoTalk Daemons Installed and Started."
echo "Check status with:"
echo "  sudo systemctl status exotalk-signaling.service"
echo "  sudo systemctl status exotalk-zrok.service"
echo "------------------------------------------------"
