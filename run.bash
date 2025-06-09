#!/bin/bash

# ROS Noetic Docker Container Runner
# This script runs the ROS Noetic development container with full device access

echo "Starting ROS Noetic Docker container..."

docker run -it --rm \
  -v $HOME:/home/$USER \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -e DISPLAY=$DISPLAY \
  --network host \
  --privileged \
  -v /dev:/dev \
  --name ros-noetic-container \
  ros-noetic-dev

echo "Container has stopped."
