#!/bin/bash
DIRNAME=$(dirname $(realpath "$0"))

if [[ -e /dev/ttyUSB0 ]] || [[ -e /dev/ttyACM0 ]]; then
  echo "Please remove a Programmator or Board first!"

  while [[ -e /dev/ttyUSB0 ]] || [[ -e /dev/ttyACM0 ]]
  do
    sleep 1
  done
fi

sudo mkdir -p /run/udev/rules.d
sudo ln -s $DIRNAME/udev/rules.d/50-wch.rules /run/udev/rules.d/50-wch.rules
sudo ln -s $DIRNAME/udev/rules.d/60-openocd.rules /run/udev/rules.d/60-openocd.rules 

sudo service udev reload

echo "Please plug-in a Programmator or Board now..."

while [[ ! -e /dev/ttyUSB0 ]] && [[ ! -e /dev/ttyACM0 ]]
do
  sleep 1
done

xhost +local:docker
docker run --rm \
            -it \
           --privileged \
           --env DISPLAY=$DISPLAY \
           --volume /tmp/.X11-unix:/tmp/.X11-unix:ro \
           --volume /run/dbus/system_bus_socket:/run/dbus/system_bus_socket:ro \
           --volume .:/home/arduino \
           $(test -e /dev/ttyUSB0 && echo "--device=/dev/ttyUSB0" | xargs) \
           $(test -e /dev/ttyACM0 && echo "--device=/dev/ttyACM0" | xargs) \
           --name arduino-ide \
           arduino-ide
xhost -local:docker

sudo unlink /run/udev/rules.d/60-openocd.rules 
sudo unlink /run/udev/rules.d/50-wch.rules

sudo service udev reload