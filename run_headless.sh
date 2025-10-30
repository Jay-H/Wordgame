#!/bin/bash

# Navigate to the project directory
cd /home/testbed/Documents/Wordgame

# Pull the latest changes
git pull origin master

# Export the Godot project
echo "Exporting new Godot project..."
godot --headless --export-release "Linux" build/server/wordsearch.x86_64

# Restart the systemd service to pick up the new executable
echo "Restarting Godot server service..."
sudo systemctl restart godot_server.service

echo "Deployment complete."
