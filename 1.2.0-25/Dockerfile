FROM ubuntu:14.04
ENV tmpdir /opt
RUN /usr/bin/apt-get update && /usr/bin/apt-get install -y libc-bin wget openssl curl sudo python-ctypes sysv-rc
COPY ./docker /usr/bin/
COPY setup.sh main.sh $tmpdir/
WORKDIR ${tmpdir}
RUN chmod 775 $tmpdir/*.sh; sync; $tmpdir/setup.sh; chmod 755 /usr/bin/docker
CMD [ "/opt/main.sh" ]
