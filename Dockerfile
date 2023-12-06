FROM almalinux:8

LABEL org.opencontainers.image.source=https://github.com/marcbull/docker-test
LABEL org.opencontainers.image.description="Test container image"
LABEL org.opencontainers.image.licenses=APACHE-2.0

RUN sed -i -re "s|enabled=0|enabled=1|g" /etc/yum.repos.d/almalinux-powertools.repo

RUN dnf -y install \
    findutils \
    which \
    vim \
  && dnf clean all \
  && rm -rf /var/cache/dnf

# Add epel repository
RUN dnf -y install epel-release \
  && dnf clean all \
  && rm -rf /var/cache/dnf

# Disable CUDA:
# ARG CUDA_RPM=cuda-repo-rhel8-12-2-local-12.2.0_535.54.03-1.x86_64.rpm
# RUN curl --proto '=https' --tlsv1.2 -sSf https://developer.download.nvidia.com/compute/cuda/12.2.0/local_installers/${CUDA_RPM} > /tmp/${CUDA_RPM} \
#   && rpm -i /tmp/${CUDA_RPM} \
#   && rm -f /tmp/${CUDA_RPM} \
#   && dnf -y install cuda \
#   && dnf clean all \
#   && rm -rf /var/cache/dnf

# Required base packages
RUN dnf -y install xz bzip2 less python3.11-pip \
  && dnf clean all \
  && rm -rf /var/cache/dnf

RUN pip3 install meson

ARG DEVTOOLSET=gcc-toolset-12
# Required for building vcpkg packages
RUN dnf -y install ${DEVTOOLSET} make cmake ninja-build git elfutils autoconf automake libtool zlib-devel curl wget zip unzip tar bison flex \
  && dnf clean all \
  && rm -rf /var/cache/dnf \
  && echo -e "source /opt/rh/${DEVTOOLSET}/enable" >> /etc/profile.d/compiler.sh

RUN dnf -y install diffutils pkgconfig nasm yasm clang rsync desktop-file-utils \
  && dnf clean all \
  && rm -rf /var/cache/dnf

RUN dnf -y install \
    pulseaudio-libs-devel vulkan-loader-devel \
    wayland-devel wayland-protocols-devel \
    mesa-libGL-devel libX11-devel libXft-devel libXext-devel libXrandr-devel libXi-devel libXcursor-devel libXdamage-devel libXinerama-devel libxkbcommon-devel libxkbcommon-x11-devel \
    perl-IPC-Cmd gtk-update-icon-cache \
  && dnf clean all \
  && rm -rf /var/cache/dnf

# Reinstall some packages to get access to deleted license texts:
RUN dnf -y reinstall libblkid lz4-libs \
  && dnf clean all \
  && rm -rf /var/cache/dnf

# Install rust and some cargo tools
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs > /tmp/rustup.sh \
  && sh /tmp/rustup.sh -y \
  && rm /tmp/rustup.sh \
  && echo -e "source \"\$HOME/.cargo/env\"" >> /etc/profile.d/rust.sh \
  && source /etc/profile.d/rust.sh \
  && cargo install cocogitto \
  && cargo install just \
  && cargo install cargo-bundle-licenses \
  && cargo install cargo-audit \
  && cargo install typos-cli \
  && cargo install cargo-version-util

# Appimage installation:
COPY appimage/setup.sh /tmp
COPY appimage/patchelf.sh /tmp
COPY appimage/linuxdeploy-plugin-gtk.patch /tmp
RUN pushd /tmp \
  && ./setup.sh \
  && rm setup.sh

# Makeself installation:
RUN dnf -y install unzip chrpath \
  && dnf clean all \
  && rm -rf /var/cache/dnf

ARG VERSION=2.5.0
RUN cd /tmp \
  && curl -LO https://github.com/megastep/makeself/releases/download/release-${VERSION}/makeself-${VERSION}.run \
  && chmod +x makeself-${VERSION}.run \
  && mkdir -p /opt \
  && cd /opt \
  && /tmp/makeself-${VERSION}.run \
  && mv makeself-${VERSION} makeself \
  && rm /tmp/makeself-${VERSION}.run
