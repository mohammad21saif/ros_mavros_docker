sudo docker run -it --rm \
    --runtime nvidia \
    --network host \
    --privileged \
    --ipc host \
    --pid host \
    -e DISPLAY=$DISPLAY \
    -e QT_X11_NO_MITSHM=1 \
    -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
    -v /dev:/dev \
    -v $HOME/.Xauthority:/root/.Xauthority:rw \
    --group-add dialout \
    jetson_ros_noetic_mavros
