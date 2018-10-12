FROM ubuntu:16.04
MAINTAINER OMSContainers@microsoft.com
LABEL vendor=Microsoft\ Corp \
com.microsoft.product="OMS Container Docker Provider" \
com.microsoft.version="2.0.0-7"
ENV tmpdir /opt
ENV APPLICATIONINSIGHTS_AUTH Mzg1NzU2ZjAtZjQ2OS00M2JiLThmMzctODc5NWZiNjFhZTgz
RUN /usr/bin/apt-get update && /usr/bin/apt-get install -y libc-bin wget openssl curl sudo python-ctypes sysv-rc net-tools rsyslog cron vim dmidecode apt-transport-https && rm -rf /var/lib/apt/lists/*
COPY setup.sh main.sh $tmpdir/
WORKDIR ${tmpdir}
RUN chmod 775 $tmpdir/*.sh; sync; $tmpdir/setup.sh
CMD [ "/opt/main.sh" ]
