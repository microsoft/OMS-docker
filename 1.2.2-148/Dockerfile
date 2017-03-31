FROM ubuntu:14.04
MAINTAINER OMSContainers@microsoft.com
LABEL vendor=Microsoft\ Corp \
com.microsoft.product="OMS Container Docker Provider" \
com.microsoft.version="1.0.0-17
ENV tmpdir /opt
RUN /usr/bin/apt-get update && /usr/bin/apt-get install -y libc-bin wget openssl curl sudo python-ctypes sysv-rc libltdl7
RUN sed -i "s/^exit 101$/exit 0/" /usr/sbin/policy-rc.d
COPY ./docker /usr/bin/
COPY setup.sh main.sh $tmpdir/
WORKDIR ${tmpdir}
RUN chmod 775 $tmpdir/*.sh; sync; $tmpdir/setup.sh; chmod 755 /usr/bin/docker
CMD [ "/opt/main.sh" ]
