# This dockerfile creates a reproducible build environment for mold.
#
# $ docker build -t registry.gitlab.com/pep10/wip/pld/dev:v0.1.0 .
# $ docker push registry.gitlab.com/pep10/wip/pld/dev:v0.1.0

FROM ubuntu:22.04
RUN apt update && apt install --no-install-recommends -y software-properties-common build-essential git \
  wget cmake libstdc++-11-dev zlib1g-dev gpg gpg-agent qemu-user cmake libssl-dev bsdmainutils file\
  gcc-i686-linux-gnu g++-i686-linux-gnu gcc-aarch64-linux-gnu g++-aarch64-linux-gnu \
  gcc-arm-linux-gnueabihf g++-arm-linux-gnueabihf gcc-riscv64-linux-gnu g++-riscv64-linux-gnu &&\
  apt clean && \
  rm -rf /var/lib/apt/lists/* && \
  cd / && \
  wget -O- https://www.openssl.org/source/openssl-3.0.2.tar.gz | tar xzf - && \
  mv openssl-3.0.2 openssl && \
  cd openssl && \
  ./Configure --prefix=/openssl && \
  make -j$(nproc)
