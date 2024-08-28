FROM ubuntu:22.04

# make /bin/sh symlink to bash instead of dash:
RUN echo "dash dash/sh boolean false" | debconf-set-selections
RUN DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash

# The Xilinx toolchain version
ARG XILVER=2024.1

# The PetaLinux base. We expect ${PETALINUX_BASE}-installer.run to be the patched installer.
# PetaLinux will be installed in /opt/${PETALINX_BASE}
# File is expected in the "resources" subdirectory
ARG PETALINUX_BASE=petalinux-v${XILVER}-final

# The PetaLinux runnable installer
ARG PETALINUX_INSTALLER=${PETALINUX_BASE}-installer.run

# The HTTP server to retrieve the files from. It should be accessible by the Docker daemon as ${HTTP_SERV}/${SDK_INSTALLER}
ARG HTTP_SERV=http://host.docker.internal:8000/resources

# Make tzdata package install non interactive. See https://serverfault.com/a/1016972/308291
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

RUN dpkg --add-architecture i386 && apt-get update && apt-get install -y \
	python3 \
	bc \
	rsync \
	apt-utils \
	tofrodos \
	iproute2 \
	gawk \
	xvfb \
	gcc-4.8 \
	git \
	make \
	net-tools \
	libncurses5-dev \
	tftpd \
	tftp-hpa \
	zlib1g-dev:i386 \
	libssl-dev \
	flex \
	bison \
	libselinux1 \
	gnupg \
	wget \
	diffstat \
	chrpath \
	socat \
	xterm \
	autoconf \
	libtool \
	tar \
	unzip \
	texinfo \
	zlib1g-dev \
	gcc-multilib \
	build-essential \
	libsdl1.2-dev \
	libglib2.0-dev \
	screen \
	expect \
	locales \
	cpio \
	sudo \
	software-properties-common \
	pax \
	gzip \
	vim \
	libgtk2.0-0 \
	&& apt-get autoremove --purge && apt-get autoclean

# Enable universe repository and update package lists
RUN apt-get update && apt-get install -y software-properties-common \
    && add-apt-repository universe \
    && apt-get update

# Append the repository information to the /etc/apt/sources.list.d/ubuntu.sources file
RUN echo -e '\nTypes: deb\nURIs: http://archive.ubuntu.com/ubuntu/\nSuites: lunar\nComponents: universe\nSigned-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg' >> /etc/apt/sources.list.d/ubuntu.sources

# Extras to add
RUN apt-get update && apt-get install -y \
	libncurses5:i386 \
	libtinfo5 \
	libgtk2.0-0:i386 \
	libfontconfig1:i386 \
	libx11-6:i386 \
	libxext6:i386 \
	libsm6:i386 \
	libxi6:i386 \
	git \
	git-core \
	diffstat \
	automake \
	zlib1g:i386 \
	xz-utils \
	debianutils \
	python3-pip \
	python3-pexpect \
	python3-git \
	iputils-ping \
	python3-jinja2 \
	dnsutils \
	&& apt-get autoremove --purge && apt-get autoclean

RUN echo "%sudo ALL=(ALL:ALL) ALL" >> /etc/sudoers \
	&& echo "%sudo ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
	&& ln -fs /bin/bash /bin/sh

# Set locale
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Add user 'petalinux' with password 'petalinux' and give it access to install directory /opt
RUN useradd -m -G dialout,sudo -p '$6$wiu9XEXx$ITRrMySAw1SXesQcP.Bm3Su2CuaByujc6Pb7Ztf4M9ES2ES7laSRwdcbgG96if4slduUxyjqvpEq2I0OhxKCa1' petalinux \
	&& chmod +w /opt \
	&& chown -R petalinux:petalinux /opt \
	&& mkdir /opt/${PETALINUX_BASE} \
	&& chmod 755 /opt/${PETALINUX_BASE} \
	&& chown petalinux:petalinux /opt/${PETALINUX_BASE}

# Install under /opt, with user petalinux
WORKDIR /opt
USER petalinux

# Install PetaLinux
RUN chown -R petalinux:petalinux .
RUN wget -q ${HTTP_SERV}/${PETALINUX_INSTALLER}
RUN chmod a+x ${PETALINUX_INSTALLER}
RUN ./${PETALINUX_FILE}${PETALINUX_INSTALLER} -y --dir /opt/${PETALINUX_BASE}
RUN rm -f ./${PETALINUX_INSTALLER}
RUN rm -f petalinux_installation_log

# Source settings at login
USER root
RUN echo "source /opt/${PETALINUX_BASE}/settings.sh" >> /etc/bash.bashrc

# Set default shell to /bin/bash
SHELL ["/bin/bash", "-c"]
ENV SHELL /bin/bash
