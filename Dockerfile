FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN <<EOT
    apt-get update
    apt-get install locales
    locale-gen en_US.UTF-8
EOT

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Zephyr SDK dependances
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
    git \
    cmake \
    ninja-build \
    gperf \
    ccache \
    dfu-util \
    device-tree-compiler \
    wget \
    python3-dev \
    python3-pip \
    python3-setuptools \
    python3-tk \
    python3-wheel \
    xz-utils \
    file \
    make \
    gcc \
    gcc-multilib \
    g++-multilib \
    libsdl2-dev \
    libmagic1 && \
    rm -rf /var/lib/apt/lists/*

RUN <<EOT
    python3 -m pip install -U --no-cache-dir pip
    pip3 install --no-cache-dir west
    pip3 install --no-cache-dir -r https://raw.githubusercontent.com/zephyrproject-rtos/zephyr/main/scripts/requirements.txt
    pip3 check
EOT

# Create 'user' account
ARG USERNAME=developer
ARG UID=1000
ARG GID=$UID

RUN <<EOT 
    apt-get update && apt-get install --no-install-recommends -y sudo
    groupadd --gid $GID $USERNAME
    useradd --uid $UID --gid $GID -m $USERNAME
    echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/${USERNAME}
    chmod 0440 /etc/sudoers.d/$USERNAME
EOT

# Install debugger openocd
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
    libtool \
    libusb-1.0-0-dev \
    usbutils \
    openocd

# Install debugger rules
ADD https://github.com/stlink-org/stlink.git stlink/
RUN mkdir -p /etc/udev/rules.d && \
    mv stlink/config/udev/rules.d /etc/udev/ && \
    rm -r stlink

# Install Zephyr SDK
ARG ZSDK_VERSION=0.16.8

RUN <<EOT
    mkdir -p /opt
	cd /opt
	wget https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${ZSDK_VERSION}/zephyr-sdk-${ZSDK_VERSION}_linux-x86_64_minimal.tar.xz
	wget -O - https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v{ZSDK_VERSION}/sha256.sum | shasum --check --ignore-missing
    tar xf zephyr-sdk-${ZSDK_VERSION}_linux-x86_64_minimal.tar.xz
	rm zephyr-sdk-${ZSDK_VERSION}_linux-x86_64_minimal.tar.xz
    mv zephyr-sdk-${ZSDK_VERSION} zephyr-sdk
	zephyr-sdk/setup.sh -t "arm-zephyr-eabi" -h -c
EOT
EOT

USER ${USERNAME}

RUN <<EOT
    /opt/zephyr-sdk/setup.sh -c
    chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.cmake
EOT

ENV ZEPHYR_TOOLCHAIN_VARIANT=zephyr
ENV PATH=/opt/zephyr-sdk/arm-zephyr-eabi/bin:$PATH
