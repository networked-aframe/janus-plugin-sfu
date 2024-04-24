FROM ubuntu:24.04
# If you want to build the docker image on Raspberry Pi OS (based on debian bullseye)
# and then copy the build artifacts on the host to run janus without docker,
# comment "FROM ubuntu:20.04" and uncomment those two lines:
# FROM debian:bullseye
# RUN curl https://sh.rustup.rs -sSf | sh -s -- -y --profile minimal
# Installing rustup is needed to have a recent cargo version (1.61.0),
# ubuntu:20.04 uses cargo 1.57.0 that is recent enough, but debian:bullseye uses cargo 1.46.0
# that has an issue that produces the error "error inflating zlib stream; class=Zlib" when getting crate dependencies.
#
# Look at the version used in
# https://github.com/meetecho/janus-gateway/blob/master/.github/workflows/janus-ci.yml

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
# Apr 17, 2024 master c4b52c34d4a7ecca6c992ba2f7f09607997d8ead
RUN git clone https://github.com/sctplab/usrsctp.git && \
    cd usrsctp && \
    git checkout c4b52c34d4a7ecca6c992ba2f7f09607997d8ead && \
    ./bootstrap && \
    ./configure --prefix=/usr --disable-static --disable-programs --disable-inet --disable-inet6 && \
    make && make install && \
    cd / && rm -rf usrsctp


# 2024-05-09 12:46 63ee713102f453447e3c912a7bb45791d4d198c5 (post v0.14.2 from 0.x branch)
RUN git clone -b 0.x https://github.com/meetecho/janus-gateway.git && \
    cd janus-gateway && \
    git checkout a7767ad30b803d96e11b491547bcf5660cb7a937 && \
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
COPY --chmod=755 start.sh /start

USER nobody:nogroup
ENTRYPOINT ["/start"]
CMD ["janus"]
