FROM ubuntu:20.04
# If you want to build the docker image on Raspberry Pi OS (based on debian bullseye)
# and then copy the build artifacts on the host to run janus without docker,
# comment "FROM ubuntu:20.04" and uncomment those two lines:
# FROM debian:bullseye
# RUN curl https://sh.rustup.rs -sSf | sh -s -- -y --profile minimal
# Installing rustup is needed to have a recent cargo version (1.61.0),
# ubuntu:20.04 uses cargo 1.57.0 that is recent enough, but debian:bullseye uses cargo 1.46.0
# that has an issue that produces the error "error inflating zlib stream; class=Zlib" when getting crate dependencies.

RUN apt-get -y update && DEBIAN_FRONTEND="noninteractive" TZ="Europe/Paris" apt-get -y upgrade
RUN apt-get -y update && DEBIAN_FRONTEND="noninteractive" TZ="Europe/Paris" apt-get install -y libmicrohttpd-dev \
    libjansson-dev \
    libssl-dev \
    libglib2.0-dev \
    libopus-dev \
    libogg-dev \
    libconfig-dev \
    libssl-dev \
    pkg-config \
    gengetopt \
    libtool \
    automake \
    build-essential \
    subversion \
    git \
    cmake \
    unzip \
    zip \
    cargo \
    wget \
    curl \
    iproute2


RUN LIBWEBSOCKET="4.3.2" && wget https://github.com/warmcat/libwebsockets/archive/v$LIBWEBSOCKET.tar.gz && \
    tar xzvf v$LIBWEBSOCKET.tar.gz && \
    cd libwebsockets-$LIBWEBSOCKET && \
    mkdir build && \
    cd build && \
    cmake -DLWS_MAX_SMP=1 -DLWS_WITHOUT_EXTENSIONS=0 -DCMAKE_INSTALL_PREFIX:PATH=/usr -DCMAKE_C_FLAGS="-fpic" .. && \
    make && make install && \
    cd / && rm -rf libwebsockets-$LIBWEBSOCKET


RUN SRTP="2.4.2" && wget https://github.com/cisco/libsrtp/archive/v$SRTP.tar.gz && \
    tar xfv v$SRTP.tar.gz && \
    cd libsrtp-$SRTP && \
    ./configure --prefix=/usr --enable-openssl && \
    make shared_library && make install && \
    cd / && rm -rf libsrtp-$SRTP


# libnice 2021-02-21 11:10 (post 0.1.18)
RUN apt-get -y --no-install-recommends install ninja-build meson && \
    apt-get remove -y libnice-dev libnice10 && \
    apt-get install -y gtk-doc-tools libgnutls28-dev && \
    git clone https://gitlab.freedesktop.org/libnice/libnice && \
    cd libnice && \
    git checkout 36aa468c4916cfccd4363f0e27af19f2aeae8604 && \
    meson --prefix=/usr build && \
    ninja -C build && \
    ninja -C build install && \
    cd / && rm -rf libnice


# datachannel build
# Jan 13, 2021 0.9.5.0 07f871bda23943c43c9e74cc54f25130459de830
RUN git clone https://github.com/sctplab/usrsctp.git && \
    cd usrsctp && \
    git checkout 0.9.5.0 && \
    ./bootstrap && \
    ./configure --prefix=/usr --disable-programs --disable-inet --disable-inet6 && \
    make && make install && \
    cd / && rm -rf usrsctp


# 2022-10-21 15:02 7b6bcdcdbe02dd05932d778592f4c03604a83684 (post v0.13.0 from 0.x branch)
RUN git clone -b 0.x https://github.com/meetecho/janus-gateway.git && \
    cd janus-gateway && \
    git checkout 7b6bcdcdbe02dd05932d778592f4c03604a83684 && \
    sh autogen.sh &&  \
    CFLAGS="${CFLAGS} -fno-omit-frame-pointer" ./configure --prefix=/usr --disable-all-plugins --disable-all-handlers && \
    make && make install && make configs && \
    cd / && rm -rf janus-gateway


RUN git clone -b master https://github.com/networked-aframe/janus-plugin-sfu.git && \
    cd janus-plugin-sfu && \
    git checkout 1914dfa7e22c793f4a684ebeb002304661270519 && \
    echo version 2 increment this line to invalidate cache of this layer while iterating build during development && \
    cargo build --release && \
    mkdir -p /usr/lib/janus/plugins && \
    mkdir -p /usr/lib/janus/events && \
    cp target/release/libjanus_plugin_sfu.so /usr/lib/janus/plugins && \
    cd / && rm -rf janus-plugin-sfu ~/.cargo

COPY confs/* /usr/etc/janus/
RUN chown -R nobody:nogroup /usr/etc/janus/
COPY start.sh /start

USER nobody:nogroup
ENTRYPOINT ["/start"]
CMD ["janus"]
