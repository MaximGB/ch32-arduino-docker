#!/bin/sh
docker build --rm --tag arduino-ide --build-arg USER_ID=$(id -u) --build-arg GROUP_ID=$(id -g) .
docker run --entrypoint "ls" --name arduino-ide arduino-ide
docker cp arduino-ide:/home/arduino ./home
docker rm arduino-ide