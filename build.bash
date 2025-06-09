#!/bin/bash

# ROS Noetic Docker Container Builder
# This script builds the ROS Noetic development container with current user settings

echo "Building ROS Noetic Docker container..."
echo "Username: $USER"
echo "User ID: $(id -u)"
echo "Group ID: $(id -g)"
echo ""

docker build \
  --build-arg USERNAME=$USER \
  --build-arg USER_UID=$(id -u) \
  --build-arg USER_GID=$(id -g) \
  -t ros-noetic-dev .

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Build completed successfully!"
    echo "Image tagged as: ros-noetic-dev"
    echo "You can now run the container using: ./run_ros_container.sh"
else
    echo ""
    echo "❌ Build failed!"
    exit 1
fi
