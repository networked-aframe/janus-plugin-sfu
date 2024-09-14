ARG IMAGE=ubuntu:24.04
FROM $IMAGE AS build
# If you want to build the docker image on Raspberry Pi OS (based on debian bookworm)
# and then copy the build artifacts on the host to run janus without docker,
# change the base image with docker build --build-arg="IMAGE=debian:bookworm"
#
# Look at the version used in
# https://github.com/meetecho/janus-gateway/blob/master/.github/workflows/janus-ci.yml

# For a debug build with libasan, add libasan8 to apt list in the two phases, uncomment JANUS_DEBUG_CFLAGS and JANUS_DEBUG_LDFLAGS and use the janus-plugin-sfu debug instructions.
# Run with:
# docker run --net=host -e EVENT_LOOPS=4 -e MESSAGE_THREADS=1 janus:latest
# to see the memory leaks on stdout when you ctrl+c the container if any. Using docker compose up doesn't show anything.

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
#    libasan8 \
    wget \
    curl \
    iproute2 && \
    apt-get -y --no-install-recommends install ninja-build meson gtk-doc-tools libgnutls28-dev && \
    apt-get remove -y libnice-dev libnice10 && \
    rm -rf /var/lib/apt/lists/*


RUN LIBWEBSOCKET="4.3.3" && wget https://github.com/warmcat/libwebsockets/archive/v$LIBWEBSOCKET.tar.gz && \
    tar xzvf v$LIBWEBSOCKET.tar.gz && \
    cd libwebsockets-$LIBWEBSOCKET && \
    mkdir build && \
    cd build && \
    cmake -DLWS_MAX_SMP=1 -DLWS_WITHOUT_EXTENSIONS=0 -DCMAKE_INSTALL_PREFIX:PATH=/usr -DCMAKE_C_FLAGS="-fpic" -DLWS_WITH_STATIC=OFF -DLWS_WITHOUT_CLIENT=ON -DLWS_WITHOUT_TESTAPPS=ON -DLWS_WITHOUT_TEST_SERVER=ON -DLWS_WITH_HTTP2=OFF .. && \
    make && make install && \
    cd / && rm -rf libwebsockets-$LIBWEBSOCKET


RUN SRTP="2.6.0" && wget https://github.com/cisco/libsrtp/archive/v$SRTP.tar.gz && \
    tar xfv v$SRTP.tar.gz && \
    cd libsrtp-$SRTP && \
    ./configure --prefix=/usr --enable-openssl && \
    make shared_library && make install && \
    cd / && rm -rf libsrtp-$SRTP


# libnice 2020-07-06 13:53 (post 0.1.18)
RUN git clone https://gitlab.freedesktop.org/libnice/libnice && \
#    apt-get -y --no-install-recommends install ninja-build meson gtk-doc-tools libgnutls28-dev && \
#    apt-get remove -y libnice-dev libnice10 && \
    cd libnice && \
    git checkout 48dac0d702b134f7b11b92602c234ba1120cc75b && \
    meson setup -Dprefix=/usr -Dlibdir=lib -Ddebug=false -Doptimization=0 -Dexamples=disabled -Dgtk_doc=disabled -Dgupnp=disabled -Dgstreamer=disabled -Dtests=disabled build && \
    ninja -C build && \
    ninja -C build install && \
    cd / && rm -rf libnice


# datachannel build
# Aug 22, 2024 master a07d9a846480f072fe53cd9f55fd014077d532af
RUN git clone https://github.com/sctplab/usrsctp.git && \
    cd usrsctp && \
    git checkout a07d9a846480f072fe53cd9f55fd014077d532af && \
    ./bootstrap && \
    ./configure --prefix=/usr --disable-static --disable-programs --disable-inet --disable-inet6 && \
    make && make install && \
    cd / && rm -rf usrsctp


# 2024-09-10 (v0.14.4 from 0.x branch)
ENV JANUS_COMMIT="4353b83ffb97775c5b97c09177690a2f09494eed"
# ENV JANUS_DEBUG_CFLAGS="-O0 -g3 -ggdb3 -fno-omit-frame-pointer -fno-optimize-sibling-calls -fsanitize=address -fsanitize-address-use-after-scope -fno-sanitize-recover=all"
# ENV JANUS_DEBUG_LDFLAGS="-fsanitize=address"
RUN git clone -b 0.x https://github.com/meetecho/janus-gateway.git && \
    cd janus-gateway && \
    git checkout ${JANUS_COMMIT} && \
    sh autogen.sh &&  \
    CFLAGS="${CFLAGS} ${JANUS_DEBUG_CFLAGS}" LDFLAGS="${JANUS_DEBUG_LDFLAGS}" ./configure --prefix=/usr --disable-all-plugins --disable-all-handlers && \
    make && make install && make configs && \
    cd / && rm -rf janus-gateway

ENV JANUS_SFU_COMMIT="44583e61acb8accee677deac6b44059c2b8df3da"
# janus-plugin-sfu release build:
RUN git clone -b master https://github.com/networked-aframe/janus-plugin-sfu.git && \
    cd janus-plugin-sfu && \
    git checkout ${JANUS_SFU_COMMIT} && \
    curl https://sh.rustup.rs -sSf | sh -s -- -y --profile minimal && \
    . "$HOME/.cargo/env" && \
    cargo build --release && \
    mkdir -p /usr/lib/janus/plugins && \
    mkdir -p /usr/lib/janus/events && \
    cp target/release/libjanus_plugin_sfu.so /usr/lib/janus/plugins && \
    cd / && rm -rf janus-plugin-sfu ~/.cargo

# janus-plugin-sfu debug build:
# RUN git clone -b master https://github.com/networked-aframe/janus-plugin-sfu.git janus-plugin-sfu && \
#     cd janus-plugin-sfu && \
#     git checkout ${JANUS_SFU_COMMIT} && \
#     curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain nightly -y && \
#     . "$HOME/.cargo/env" && \
#     rustup component add rust-src --toolchain nightly-x86_64-unknown-linux-gnu && \
#     RUSTFLAGS=-Zsanitizer=address cargo build -Zbuild-std --target x86_64-unknown-linux-gnu && \
#     mkdir -p /usr/lib/janus/plugins && \
#     mkdir -p /usr/lib/janus/events && \
#     cp target/x86_64-unknown-linux-gnu/debug/libjanus_plugin_sfu.so /usr/lib/janus/plugins && \
#     cd / && rm -rf janus-plugin-sfu ~/.cargo

FROM $IMAGE
RUN apt-get -y update && DEBIAN_FRONTEND="noninteractive" apt-get install -y \
    libmicrohttpd12 \
    libconfig9 \
    libglib2.0-0 \
    libjansson4 \
#    libasan8 \
    curl \
    iproute2 && \
    rm -rf /var/lib/apt/lists/*
COPY --from=build /usr/lib/libwebsockets.so* /usr/lib/
COPY --from=build /usr/lib/libsrtp2.so* /usr/lib/
COPY --from=build /usr/lib/libnice.so* /usr/lib/
COPY --from=build /usr/lib/libusrsctp.so* /usr/lib/
COPY --from=build /usr/lib/janus /usr/lib/janus
COPY --from=build /usr/bin/janus /usr/bin/janus

COPY confs/* /usr/etc/janus/
RUN chown -R nobody:nogroup /usr/etc/janus/
COPY --chmod=755 start.sh /start

USER nobody:nogroup
ENTRYPOINT ["/start"]
CMD ["janus"]
