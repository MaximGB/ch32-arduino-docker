#!/bin/sh
docker build --rm --tag arduino-ide --build-arg USER_ID=$(id -u) --build-arg GROUP_ID=$(id -g) .