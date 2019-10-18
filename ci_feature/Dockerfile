FROM ubuntu:16.04
MAINTAINER OMSContainers@microsoft.com
LABEL vendor=Microsoft\ Corp \
    com.microsoft.product="OMS Container Docker Provider" \
    com.microsoft.version="7.0.0-5"
ENV tmpdir /opt
ENV APPLICATIONINSIGHTS_AUTH OTQzNWI0M2YtOTdkNS00ZGVkLThkOTAtYjA0Nzk1OGU2ZTg3
ENV AGENT_VERSION ciprod10182019
ENV HOST_MOUNT_PREFIX /hostfs
ENV HOST_PROC /hostfs/proc
ENV HOST_SYS /hostfs/sys
ENV HOST_ETC /hostfs/etc
ENV HOST_VAR /hostfs/var
ENV AZMON_COLLECT_ENV False
RUN /usr/bin/apt-get update && /usr/bin/apt-get install -y libc-bin wget openssl curl sudo python-ctypes sysv-rc net-tools rsyslog cron vim dmidecode apt-transport-https && rm -rf /var/lib/apt/lists/*
COPY setup.sh main.sh defaultpromenvvariables defaultpromenvvariables-rs $tmpdir/
WORKDIR ${tmpdir}
RUN chmod 775 $tmpdir/*.sh; sync; $tmpdir/setup.sh
CMD [ "/opt/main.sh" ]
