FROM golang:1.10 AS builder

WORKDIR /go/src/out_oms/

COPY Makefile ./go/plugins/glide.yaml ./go/plugins/glide.lock ./go/plugins/*.go /go/src/out_oms/

RUN curl https://glide.sh/get | sh \
&& make glide all

FROM fluent/fluent-bit:0.13.7

COPY --from=builder /go/src/out_oms/out_oms.so /fluent-bit/bin/
COPY ./conf/*.conf /fluent-bit/etc/
COPY start.sh /start.sh

RUN apt-get update \
    && apt-get install  procps vim -y 
        
CMD ["/start.sh"]
