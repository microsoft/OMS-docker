FROM ubuntu:18.04
MAINTAINER OMSContainers@microsoft.com
LABEL vendor=Microsoft\ Corp \
com.microsoft.product="OMS Container Docker Provider" \
com.microsoft.version="1.0.0-39"
ENV tmpdir /opt
RUN /usr/bin/apt-get update && /usr/bin/apt-get install -y libc-bin wget openssl curl sudo python-ctypes gpg net-tools rsyslog cron vim dmidecode apt-transport-https && rm -rf /var/lib/apt/lists/*
COPY setup.sh main.sh $tmpdir/
WORKDIR ${tmpdir}
RUN chmod 775 $tmpdir/*.sh; sync; $tmpdir/setup.sh
CMD [ "/opt/main.sh" ]
