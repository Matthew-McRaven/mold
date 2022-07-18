# This dockerfile creates a reproducible build environment for mold.
#
# $ docker build -t rui314/mold-builder:v1-$(uname -m) .
# $ docker push rui314/mold-builder:v1-$(uname -m)

FROM ubuntu:22.04
RUN apt install --no-install-recommends -y software-properties-common build-essential git \
  wget cmake libstdc++-11-dev zlib1g-dev gpg gpg-agent qemu-user \
  gcc-i686-linux-gnu g++-i686-linux-gnu gcc-aarch64-linux-gnu g++-aarch64-linux-gnu \
  gcc-arm-linux-gnueabihf g++-arm-linux-gnueabihf gcc-riscv64-linux-gnu g++-riscv64-linux-gnu
  apt clean && \
  rm -rf /var/lib/apt/lists/* && \
  cd / && \
  wget -O- https://www.openssl.org/source/openssl-3.0.2.tar.gz | tar xzf - && \
  mv openssl-3.0.2 openssl && \
  cd openssl && \
  ./Configure --prefix=/openssl && \
  make -j$(nproc)
