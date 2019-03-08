FROM ubuntu:16.04
MAINTAINER OMSContainers@microsoft.com
LABEL vendor=Microsoft\ Corp \
com.microsoft.product="OMS Container Docker Provider" \
com.microsoft.version="2.0.0-7"
ENV tmpdir /opt
ENV APPLICATIONINSIGHTS_AUTH OTQzNWI0M2YtOTdkNS00ZGVkLThkOTAtYjA0Nzk1OGU2ZTg3
ENV AGENT_VERSION ciprod02212019
ENV AZMON_COLLECT_ENV False
RUN /usr/bin/apt-get update && /usr/bin/apt-get install -y libc-bin wget openssl curl sudo python-ctypes sysv-rc net-tools rsyslog cron vim dmidecode apt-transport-https && rm -rf /var/lib/apt/lists/*
COPY setup.sh main.sh $tmpdir/
WORKDIR ${tmpdir}
RUN chmod 775 $tmpdir/*.sh; sync; $tmpdir/setup.sh
CMD [ "/opt/main.sh" ]
