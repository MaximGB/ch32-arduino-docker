#
# Intermediate step
#
FROM  ubuntu:latest AS intermediate

# Install required dependencies for the intermediate container
RUN apt update && \
  apt install -y --no-install-recommends \
  curl \
  unzip \
  ca-certificates && \
  rm -rf /var/lib/apt/lists/*

# Download the latest Arduino IDE release version
RUN curl -L -o arduino.zip $(curl --silent https://api.github.com/repos/arduino/arduino-ide/releases/latest | grep "browser_download_url.*Linux_64bit.zip" | cut -d : -f 2,3 | xargs)

# Unzip the Arduino Pro IDE into /opt
RUN unzip /arduino.zip -d /opt/arduino-ide && rm /arduino.zip

# No need since Arduino IDE v2.3.4
# Rename /opt/arduino-ide_x.y.z-blah-blah to just /opt/arduino-ide
# RUN mv /opt/arduino* /opt/arduino-ide

#
# Final image build step
#
FROM  ubuntu:latest

# These ARGs are filled in build.sh script with building user uid:gid, they are needed 
# to connect to host's XServer from Docker container
ARG   USERNAME=arduino
ARG   USER_ID
ARG   GROUP_ID

# Non interactive install, if any
ENV DEBIAN_FRONTEND=noninteractive

# Installing Arduino-IDE required dependencies
RUN apt update && \
  apt install -y --no-install-recommends \
  ca-certificates \
  sudo \
  udev \
  libgtk-3-0 \
  libnss3 \
  libdrm2 \
  libgbm1 \
  libasound2t64 \
  libx11-xcb1 \
  libsecret-1-0 \
  libxkbfile1 \
  libcanberra-gtk3-module \
  libgl1 && \
  rm -rf /var/lib/apt/lists/*

# Setting up container user
RUN   userdel -r ubuntu
RUN   useradd --non-unique -U -m -u ${USER_ID} ${USERNAME}
RUN   echo "${USERNAME}:${USERNAME}" | chpasswd
RUN   usermod -a -G sudo,dialout,plugdev ${USERNAME}

# Copy the extracted Arduino IDE from the intermediate container
COPY --from=intermediate /opt/arduino-ide /opt/arduino-ide

# This seems to be needed to run Arduino IDE in chrome-sandbox mode
RUN  chmod 4755 /opt/arduino-ide/chrome-sandbox

# Start working as non-root user
USER  $USERNAME
WORKDIR /home/${USERNAME}

# Installing WC32V003 Arduino core to user home directory
ARG ARDUINO_CLI=/opt/arduino-ide/resources/app/lib/backend/resources/arduino-cli 
RUN ${ARDUINO_CLI} update 
ARG WCH_ARDUINO_CORE_URL=https://github.com/openwch/board_manager_files/raw/main/package_ch32v_index.json
RUN ${ARDUINO_CLI} --additional-urls ${WCH_ARDUINO_CORE_URL} core install WCH:ch32v
# WCH:ch32v Arduino core contains WCH SDK which contains some required so-libraries which also should be installed
# this is done by running start.sh from the SDK
RUN cd ~/.arduino15/packages/WCH/tools/beforeinstall/1.0.0/ && echo ${USERNAME} | sudo -S ./start.sh

# Run Arduino-IDE upon startup
ENTRYPOINT ["/opt/arduino-ide/arduino-ide"]