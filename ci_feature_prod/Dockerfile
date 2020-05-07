FROM ubuntu:18.04
MAINTAINER OMSContainers@microsoft.com
LABEL vendor=Microsoft\ Corp \
    com.microsoft.product="OMS Container Docker Provider" \
    com.microsoft.version="1.0.0-0"
ENV tmpdir /opt
ENV APPLICATIONINSIGHTS_AUTH NzAwZGM5OGYtYTdhZC00NThkLWI5NWMtMjA3ZjM3NmM3YmRi
ENV AGENT_VERSION cioneagent05062020
ENV MALLOC_ARENA_MAX 2
ENV HOST_MOUNT_PREFIX /hostfs
ENV HOST_PROC /hostfs/proc
ENV HOST_SYS /hostfs/sys
ENV HOST_ETC /hostfs/etc
ENV HOST_VAR /hostfs/var
ENV AZMON_COLLECT_ENV False
ENV KUBE_CLIENT_BACKOFF_BASE 1 
ENV KUBE_CLIENT_BACKOFF_DURATION 0
RUN /usr/bin/apt-get update && /usr/bin/apt-get install -y libc-bin wget openssl curl sudo python-ctypes init-system-helpers  net-tools rsyslog cron vim dmidecode apt-transport-https gnupg && rm -rf /var/lib/apt/lists/*
COPY setup.sh main.sh defaultpromenvvariables defaultpromenvvariables-rs mdsd.xml envmdsd $tmpdir/
WORKDIR ${tmpdir}
RUN chmod 775 $tmpdir/*.sh; sync; $tmpdir/setup.sh
CMD [ "/opt/main.sh" ]
