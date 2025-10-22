# Base image
FROM dustynv/ros:noetic-ros-base-l4t-r35.2.1

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

RUN sudo rm -f /etc/apt/sources.list.d/ros-*.list
RUN sudo rm -f /etc/apt/sources.list.d/ros-latest.list
RUN sudo rm -f /etc/apt/sources.list.d/ros1-latest.list


# Update system and install base tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    curl \
    python3-pip \
    python3-empy \
    python3-setuptools \
    python3-rosdep \
    python3-vcstool \
    geographiclib-tools \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip and install catkin tools
RUN pip3 install --upgrade pip
RUN pip3 install catkin-tools rosdistro rosinstall

# Setup ROS workspace for MAVROS
RUN mkdir -p /root/catkin_ws/src

WORKDIR /root/catkin_ws/src

# Download MAVROS + extras source
RUN rosinstall_generator mavros mavros_extras --rosdistro noetic --deps --wet-only --tar > /root/noetic-mavros.rosinstall \
    && vcs import < /root/noetic-mavros.rosinstall

WORKDIR /root/catkin_ws

# Initialize rosdep and install dependencies
RUN rosdep update

RUN rosdep install --from-paths src --ignore-src --rosdistro noetic -y

# Build MAVROS
RUN /bin/bash -c "source /opt/ros/noetic/setup.bash && catkin build"

# Install GeographicLib datasets
RUN wget https://raw.githubusercontent.com/mavlink/mavros/master/mavros/scripts/install_geographiclib_datasets.sh \
    && chmod +x install_geographiclib_datasets.sh \
    && ./install_geographiclib_datasets.sh \
    && rm install_geographiclib_datasets.sh

# Source workspace on container start
RUN echo "source /root/catkin_ws/devel/setup.bash" >> /root/.bashrc

# Set working directory
WORKDIR /root/catkin_ws
