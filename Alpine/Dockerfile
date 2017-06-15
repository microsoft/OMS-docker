FROM alpine
MAINTAINER OMSContainers@microsoft.com
LABEL vendor=Microsoft\ Corp \
com.microsoft.product="OMS Container Docker Provider" \
com.microsoft.version="1.0.0-25"
ENV tmpdir /opt
RUN apk update && apk add --update libc-bin wget openssl curl sudo python-ctypes sysv-rc net-tools rsyslog cron vim
COPY setup.sh main.sh $tmpdir/
WORKDIR ${tmpdir}
RUN chmod 775 $tmpdir/*.sh; sync; $tmpdir/setup.sh
CMD [ "/opt/main.sh" ]
