FROM alpine AS airvpn-hummingbird-build
WORKDIR /build/hummingbird
RUN echo "https://dl-cdn.alpinelinux.org/alpine/edge/testing" >>/etc/apk/repositories
RUN apk add --no-cache build-base wget git lz4-dev mbedtls-dev \
                       mlocate bash asio-dev curl-dev libxml2-dev \
                       lzo-dev xz-dev crypto++-dev && \
    cd /build && \
    git clone https://github.com/fschaeck/openvpn3-airvpn.git && \
    git clone https://gitlab.com/fschaeckermann/hummingbird.git

    #    -O0 -ggdb -g3 \\
RUN cd /build/hummingbird && \
    export PATH && \
    g++ -fwhole-program \
        -Ofast \
        -Wall \
        -Wno-sign-compare \
        -Wno-unused-parameter \
        -std=c++14 \
        -flto=4 \
        -Wl,--no-as-needed \
        -Wunused-local-typedefs \
        -Wunused-variable \
        -Wno-shift-count-overflow \
        -pthread \
        -DON_ALPINE_LINUX \
        -DENABLE_DCO \
        -DHAVE_LZ4 \
        -DUSE_MBEDTLS \
        -DUSE_ASIO \
        -DASIO_STANDALONE \
        -DASIO_NO_DEPRECATED \
        -I/usr/lib/asio/asio/include \
        -I/build/openvpn3-airvpn \
        -I/build/openvpn3-airvpn/openvpn \
        -I/usr/include/libxml2 \
        /build/hummingbird/src/hummingbird.cpp \
        /build/hummingbird/src/localnetwork.cpp \
        /build/hummingbird/src/dnsmanager.cpp \
        /build/hummingbird/src/netfilter.cpp \
        /build/hummingbird/src/airvpntools.cpp \
        /build/hummingbird/src/optionparser.cpp \
        /build/hummingbird/src/base64.cpp \
        /build/hummingbird/src/execproc.c \
        -lmbedtls \
        -lmbedx509 \
        -lmbedcrypto \
        -llz4 \
        -lxml2 \
        -llzma \
        -lcryptopp \
        -lcurl \
        -o hummingbird
RUN strip /build/hummingbird/hummingbird

FROM alpine

RUN echo "https://dl-cdn.alpinelinux.org/alpine/edge/testing" >>/etc/apk/repositories; \
    apk add --no-cache wget curl libxml2 lz4-libs lzo xz mbedtls \
                       tini crypto++ iptables ip6tables kmod

# RUN apk add --no-cache gdbserver iputils-ping traceroute telnet iproute2 vim && \

COPY --from=airvpn-hummingbird-build /build/hummingbird/hummingbird /usr/bin/hummingbird
COPY entrypoint.sh healthcheck.sh /

HEALTHCHECK --interval=5s --timeout=1s --start-period=5s \
    CMD /healthcheck.sh

ENTRYPOINT ["/sbin/tini", "--", "/entrypoint.sh"]

