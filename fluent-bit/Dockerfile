FROM golang:1.10 AS builder

WORKDIR /go/src/out_oms/

COPY Makefile Gopkg.* ./go/src/*.go /go/src/out_oms/
RUN go get -u github.com/golang/dep/cmd/dep \
 && make dep all

FROM fluent/fluent-bit:0.13.7

COPY --from=builder /go/src/out_oms/out_oms.so /fluent-bit/bin/
COPY *.conf /fluent-bit/etc/
COPY start.sh /start.sh

CMD ["/start.sh"]