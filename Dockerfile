ARG HUMMINGBIRD_VERSION=v1.1.4
ARG OPENVPN3_AIRVPN_VERSION=2022-03-01

FROM alpine AS airvpn-hummingbird-build

ARG HUMMINGBIRD_VERSION
ARG OPENVPN3_AIRVPN_VERSION

WORKDIR /build/hummingbird
RUN echo "https://dl-cdn.alpinelinux.org/alpine/edge/testing" >>/etc/apk/repositories
RUN apk add --no-cache build-base curl git lz4-dev mbedtls-dev \
                       mlocate bash asio-dev curl-dev libxml2-dev \
                       lzo-dev xz-dev crypto++-dev 
RUN cd /build && \
    echo "Cloning git repository fschaeck/opnevpn3-airvpn version ${OPENVPN3_AIRVPN_VERSION}" && \
    git clone https://github.com/fschaeck/openvpn3-airvpn.git && \
    cd openvpn3-airvpn && \
    git checkout "${OPENVPN3_AIRVPN_VERSION}" && \
    cd /build && \
    echo "Cloning gitlab repository fschaeckermann/hummingbird version ${HUMMINGBIRD_VERSION}" && \
    git clone https://gitlab.com/fschaeckermann/hummingbird.git && \
    echo "Cloned 1" && \
    cd hummingbird && \
    echo "Cloned 2" && \
    git checkout "${HUMMINGBIRD_VERSION}" && \
    echo "Cloned 3"
#    -O0 -ggdb -g3
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
        src/hummingbird.cpp \
        src/localnetwork.cpp \
        src/dnsmanager.cpp \
        src/netfilter.cpp \
        src/airvpntools.cpp \
        src/optionparser.cpp \
        src/base64.cpp \
        src/execproc.c \
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

