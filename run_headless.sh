#!/bin/bash

# Navigate to the project directory
cd /home/christopherhaddad12/my_game_server/Wordgame

# Pull the latest changes
git pull origin master

# Export the Godot project
echo "Exporting new Godot project..."
../Godot_v4.4-stable_linux.x86_64 --headless --export-release "Linux" build/server/wordsearch.x86_64

# Restart the systemd service to pick up the new executable
echo "Restarting Godot server service..."
pkill Godot_v4
../Godot_v4.4-stable_linux.x86_64  --headless --main-pack build/server/wordsearch.x86_64 

echo "Deployment complete."
