#!/usr/bin/env sh

set -e

/fluent-bit/bin/fluent-bit -c /fluent-bit/etc/fluent-bit.conf \
                           -e /fluent-bit/bin/out_oms.so "$@"