FROM ubuntu:focal
ARG USERNAME
ARG USER_UID
ARG USER_GID=$USER_UID

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Set the locale
RUN apt-get update && apt-get install -y locales && \
    locale-gen en_US en_US.UTF-8 && \
    update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 && \
    export LANG=en_US.UTF-8

# Set the timezone
ENV ROS_VERSION=1
ENV ROS_DISTRO=noetic
ENV ROS_PYTHON_VERSION=3
ENV TZ=Europe/Berlin
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Setup the sources
RUN apt-get update && apt-get install -y software-properties-common curl sudo && \
    sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list' && \
    curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | apt-key add -

# Install ROS Noetic packages
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y ros-noetic-desktop-full

# Install MAVROS and dependencies
RUN apt-get update && apt-get install -y \
    ros-noetic-mavros \
    ros-noetic-mavros-extras \
    ros-noetic-mavros-msgs \
    python3-pip

# Install GeographicLib datasets required by MAVROS
RUN wget https://raw.githubusercontent.com/mavlink/mavros/master/mavros/scripts/install_geographiclib_datasets.sh && \
    chmod +x install_geographiclib_datasets.sh && \
    ./install_geographiclib_datasets.sh && \
    rm install_geographiclib_datasets.sh

# Install bootstrap tools
RUN apt-get update && apt-get install --no-install-recommends -y \
    build-essential \
    git \
    nano \
    iputils-ping \
    wget \
    python3-rosdep \
    python3-rosinstall \
    python3-rosinstall-generator \
    python3-wstool \
    && rm -rf /var/lib/apt/lists/*

# Bootstrap rosdep
RUN rosdep init && \
    rosdep update

# Create a MAVROS configuration directory and set parameters to allow all plugins
RUN mkdir -p /opt/ros/noetic/share/mavros/config && \
    echo "# MAVROS configuration to allow all plugins\n\
plugin_allowlist:\n\
  - '*'\n\
\n\
# Enable motor control\n\
safety_allowed_area:\n\
  enable: false\n\
\n\
command:\n\
  use_comp_id_system_control: true\n\
" > /opt/ros/noetic/share/mavros/config/px4_config.yaml

# Create the user
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# Set up user environment
USER $USERNAME
WORKDIR /home/$USERNAME

# Environment setup
RUN echo 'source /opt/ros/noetic/setup.bash' >> ~/.bashrc

# ROS entrypoint script
USER root
RUN echo '#!/usr/bin/env bash' > /ros_entrypoint.sh && \
    echo 'source /opt/ros/noetic/setup.bash' >> /ros_entrypoint.sh && \
    echo 'exec "$@"' >> /ros_entrypoint.sh && \
    chmod +x /ros_entrypoint.sh

USER $USERNAME
ENTRYPOINT ["/ros_entrypoint.sh"]
CMD ["bash"]
