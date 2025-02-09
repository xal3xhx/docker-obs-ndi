FROM ubuntu:20.04

ARG DEBIAN_FRONTEND="noninteractive"

# for the VNC connection
EXPOSE 5900

# for the browser VNC client
EXPOSE 5901

# Use environment variable to allow custom VNC passwords
ENV VNC_PASSWD=123456

#Add needed nvidia environment variables for https://github.com/NVIDIA/nvidia-docker
ENV NVIDIA_DRIVER_CAPABILITIES="compute,video,utility"

# Make sure the dependencies are met
RUN apt-get update \
	&& apt install -y tigervnc-standalone-server fluxbox avahi-daemon xterm git build-essential cmake curl ffmpeg git libboost-dev libnss3 mesa-utils qtbase5-dev strace x11-xserver-utils net-tools python python-numpy scrot wget software-properties-common vlc jq intel-opencl-icd udev unrar wget qt5-image-formats-plugins \
	&& sed -i 's/geteuid/getppid/' /usr/bin/vlc \
	&& add-apt-repository ppa:obsproject/obs-studio \
	&& git clone --branch v1.0.0 --single-branch https://github.com/novnc/noVNC.git /opt/noVNC \
	&& git clone --branch v0.8.0 --single-branch https://github.com/novnc/websockify.git /opt/noVNC/utils/websockify \
	&& ln -s /opt/noVNC/vnc.html /opt/noVNC/index.html \
	&& mkdir -p /config/obs-studio /root/.config/ \
	&& ln -s /config/obs-studio/ /root/.config/obs-studio \
	&& apt install -y obs-studio \
	&& echo "**** add Intel repo ****" \
	&& curl -sL https://repositories.intel.com/graphics/intel-graphics.key | apt-key add - \
	&& echo 'deb [arch=amd64] https://repositories.intel.com/graphics/ubuntu focal main' > /etc/apt/sources.list.d/intel.list \
	&& echo "**** install runtime packages ****" \
	&& apt-get update \
	&& apt-get clean -y \
# Copy various files to their respective places
	&& wget -q -O /opt/container_startup.sh https://raw.githubusercontent.com/patrickstigler/docker-obs-ndi/master/container_startup.sh \
	&& wget -q -O /opt/x11vnc_entrypoint.sh https://raw.githubusercontent.com/patrickstigler/docker-obs-ndi/master/x11vnc_entrypoint.sh \
	&& mkdir -p /opt/startup_scripts \
	&& wget -q -O /opt/startup_scripts/startup.sh https://raw.githubusercontent.com/patrickstigler/docker-obs-ndi/master/startup.sh \
	&& wget -q -O /tmp/libndi4_4.5.1-1_amd64.deb https://github.com/Palakis/obs-ndi/releases/download/4.9.1/libndi4_4.5.1-1_amd64.deb \
	&& wget -q -O /tmp/obs-ndi_4.9.1-1_amd64.deb https://github.com/Palakis/obs-ndi/releases/download/4.9.1/obs-ndi_4.9.1-1_amd64.deb \
	&& wget -q -O /tmp/obs-websocket-5.0.1-Ubuntu64.deb https://github.com/obsproject/obs-websocket/releases/download/5.0.1/obs-websocket-5.0.1-Ubuntu64.deb \
# Download and install the plugins for NDI
	&& dpkg -i /tmp/*.deb \
	&& rm -rf /tmp/*.deb \
	&& rm -rf /var/lib/apt/lists/* \
	&& chmod +x /opt/*.sh \
	&& chmod +x /opt/startup_scripts/*.sh 
	 
# Add menu entries to the container
RUN echo "?package(bash):needs=\"X11\" section=\"DockerCustom\" title=\"OBS Screencast\" command=\"obs\"" >> /usr/share/menu/custom-docker \
	&& echo "?package(bash):needs=\"X11\" section=\"DockerCustom\" title=\"Xterm\" command=\"xterm -ls -bg black -fg white\"" >> /usr/share/menu/custom-docker && update-menus
VOLUME ["/config"]
ENTRYPOINT ["/opt/container_startup.sh"]
