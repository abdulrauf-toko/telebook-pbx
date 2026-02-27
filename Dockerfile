FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

# -------------------------
# System dependencies
# -------------------------
RUN apt-get update && apt-get install -y \
    build-essential cmake automake autoconf libtool-bin pkg-config \
    git wget curl ca-certificates \
    libssl-dev zlib1g-dev libdb-dev unixodbc-dev \
    libncurses5-dev libexpat1-dev libgdbm-dev \
    bison erlang-dev libtpl-dev libtiff5-dev uuid-dev \
    libpcre2-dev libedit-dev libsqlite3-dev \
    libcurl4-openssl-dev nasm \
    libogg-dev libspeex-dev libspeexdsp-dev \
    libldns-dev \
    python3-dev \
    libavformat-dev libswscale-dev libavresample-dev \
    liblua5.2-dev \
    libopus-dev \
    libpq-dev \
    libsndfile1-dev libflac-dev libvorbis-dev \
    libshout3-dev libmpg123-dev libmp3lame-dev \
    && rm -rf /var/lib/apt/lists/*

# -------------------------
# Build libs
# -------------------------
WORKDIR /usr/src

RUN git clone https://github.com/signalwire/libks.git
RUN git clone https://github.com/freeswitch/sofia-sip.git
RUN git clone https://github.com/freeswitch/spandsp.git
RUN git clone https://github.com/signalwire/signalwire-c.git

RUN cd libks && \
    cmake . -DCMAKE_INSTALL_PREFIX=/usr -DWITH_LIBBACKTRACE=1 && \
    make -j$(nproc) && make install

RUN cd sofia-sip && \
    ./bootstrap.sh && \
    ./configure --prefix=/usr --with-pic --disable-stun && \
    make -j$(nproc) && make install

RUN cd spandsp && \
    ./bootstrap.sh && \
    ./configure --prefix=/usr --with-pic && \
    make -j$(nproc) && make install

RUN cd signalwire-c && \
    cmake . -DCMAKE_INSTALL_PREFIX=/usr && \
    make -j$(nproc) && make install

# -------------------------
# Build FreeSWITCH
# -------------------------
RUN git clone https://github.com/signalwire/freeswitch.git

#COPY modules.conf /usr/src/freeswitch/build/modules.conf

WORKDIR /usr/src/freeswitch

RUN ./bootstrap.sh -j
RUN ./configure
RUN make -j$(nproc)
RUN make install
RUN make sounds-install moh-install

# -------------------------
# Runtime
# -------------------------
EXPOSE 5060/udp 5060/tcp 5080/udp 5080/tcp

CMD ["/usr/local/freeswitch/bin/freeswitch", "-nonat"]
