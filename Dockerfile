FROM nvcr.io/nvidia/l4t-base:35.3.1

ARG USERNAME
ARG USER_UID
ARG USER_GID=$USER_UID

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Set the locale
RUN apt-get update && apt-get install -y locales && \
    locale-gen en_US en_US.UTF-8 && \
    update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 && \
    rm -rf /var/lib/apt/lists/*
ENV LANG=en_US.UTF-8

# Set timezone
ENV TZ=Europe/Berlin
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# --- ROS Setup ---
ENV ROS_VERSION=1
ENV ROS_DISTRO=noetic
ENV ROS_PYTHON_VERSION=3

RUN apt-get update && apt-get install -y \
    software-properties-common \
    curl \
    sudo \
    lsb-release \
    gnupg2 && \
    curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc \
    | gpg --dearmor -o /usr/share/keyrings/ros-archive-keyring.gpg && \
    echo "deb [arch=arm64 signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" \
    > /etc/apt/sources.list.d/ros-latest.list && \
    rm -rf /var/lib/apt/lists/*

# Install ROS Noetic Desktop-Full
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y ros-noetic-desktop-full && \
    rm -rf /var/lib/apt/lists/*

# Install MAVROS and dependencies
RUN apt-get update && apt-get install -y \
    ros-noetic-mavros \
    ros-noetic-mavros-extras \
    ros-noetic-mavros-msgs \
    python3-pip && \
    rm -rf /var/lib/apt/lists/*

# Install GeographicLib datasets for MAVROS
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
RUN rosdep init || true && \
    rosdep update

# Configure MAVROS parameters (enable all plugins)
RUN mkdir -p /opt/ros/${ROS_DISTRO}/share/mavros/config && \
    echo "# MAVROS configuration\n\
plugin_allowlist:\n\
  - '*'\n\
safety_allowed_area:\n\
  enable: false\n\
command:\n\
  use_comp_id_system_control: true\n" \
    > /opt/ros/${ROS_DISTRO}/share/mavros/config/px4_config.yaml

# Create non-root user
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# User environment
USER $USERNAME
WORKDIR /home/$USERNAME
RUN echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> ~/.bashrc

# ROS entrypoint
USER root
RUN echo '#!/usr/bin/env bash' > /ros_entrypoint.sh && \
    echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> /ros_entrypoint.sh && \
    echo 'exec "$@"' >> /ros_entrypoint.sh && \
    chmod +x /ros_entrypoint.sh

USER $USERNAME
ENTRYPOINT ["/ros_entrypoint.sh"]
CMD ["bash"]
