FROM ubuntu:20.04
MAINTAINER OMSContainers@microsoft.com
LABEL vendor=Microsoft\ Corp \
com.microsoft.product="OMS Container Docker Provider" \
com.microsoft.version="1.0.0-37"
ENV tmpdir /opt
RUN /usr/bin/apt-get update && /usr/bin/apt-get install -y libc-bin wget python-ctypes python2 python-is-python2 openssl curl sudo net-tools rsyslog cron vim dmidecode apt-transport-https gpg && rm -rf /var/lib/apt/lists/*
COPY setup.sh main.sh $tmpdir/
WORKDIR ${tmpdir}
RUN chmod 775 $tmpdir/*.sh; sync; $tmpdir/setup.sh
CMD [ "/opt/main.sh" ]
