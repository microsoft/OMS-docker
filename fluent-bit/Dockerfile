FROM gcr.io/google-containers/debian-base-amd64:0.3 as builder

# Fluent Bit version
ENV FLB_MAJOR 0
ENV FLB_MINOR 13
ENV FLB_PATCH 7
ENV FLB_VERSION 0.13.7

ENV DEBIAN_FRONTEND noninteractive

ENV FLB_TARBALL http://github.com/fluent/fluent-bit/archive/v$FLB_VERSION.zip

RUN mkdir -p /fluent-bit/bin /fluent-bit/etc /fluent-bit/log /tmp/src/ /fluent-bit/plugins

RUN apt-get update \
    && apt-get dist-upgrade -y \
    && apt-get install -y \
       build-essential \
       cmake \
       make \
       wget \
       unzip \
       libsystemd-dev \
       libssl1.0-dev \
       libasl-dev \
    && wget -O "/tmp/fluent-bit-${FLB_VERSION}.zip" ${FLB_TARBALL} \
    && cd /tmp && unzip "fluent-bit-$FLB_VERSION.zip" \
    && cd "fluent-bit-$FLB_VERSION"/build/ \
    && cmake -DFLB_DEBUG=On \
          -DFLB_TRACE=Off \
          -DFLB_JEMALLOC=On \
          -DFLB_BUFFERING=On \
          -DFLB_TLS=On \
          -DFLB_WITHOUT_SHARED_LIB=On \
          -DFLB_WITHOUT_EXAMPLES=On \
          -DFLB_HTTP_SERVER=On \
          -DFLB_PROXY_GO=On \
          -DFLB_OUT_KAFKA=On .. \
    && make \
    && install bin/fluent-bit /fluent-bit/bin/

# Configuration files
COPY fluent-bit.conf \
     parsers.conf \
     parsers_java.conf \
     parsers_mult.conf \
     parsers_openstack.conf \
     parsers_cinder.conf \
     /fluent-bit/etc/

FROM gcr.io/google-containers/debian-base-amd64:0.3
MAINTAINER Eduardo Silva <eduardo@treasure-data.com>
LABEL Description="Fluent Bit docker image" Vendor="Fluent Organization" Version="1.1"

RUN apt-get update \
    && apt-get dist-upgrade -y \
    && apt-get install --no-install-recommends ca-certificates libssl1.0.2 wget -y \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get autoclean
COPY --from=builder /fluent-bit /fluent-bit

RUN apt-get update \
    && apt-get dist-upgrade -y \
    && apt-get install --no-install-recommends wget procps -y \
    && wget -O /fluent-bit/plugins/out_oms.so https://github.com/r-dilip/goPlugins-fluentbit/releases/download/0.1/out_oms.so \
    && rm -rf /var/lib/apt/lists/* 

#
EXPOSE 2020

# Entry point
CMD ["/fluent-bit/bin/fluent-bit", "-c", "/fluent-bit/etc/fluent-bit.conf", "-e", "/fluent-bit/plugins/out_oms.so"]
