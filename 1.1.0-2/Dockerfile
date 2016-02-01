FROM ubuntu:14.04
RUN /usr/bin/apt-get update && /usr/bin/apt-get install -y libc-bin wget openssl curl sudo python-ctypes sysv-rc
COPY ./docker /usr/bin/
COPY setup.sh main.sh omsagent.conf container.conf docker-cimprov-1.0.0-0.universal.x86_64.sh /root/
WORKDIR /root
RUN chmod 775 /root/*.sh; /root/setup.sh; chmod 755 /usr/bin/docker
RUN chown omsagent /root/*.conf; mv /root/omsagent.conf /etc/opt/microsoft/omsagent/conf/omsagent.conf; mv /root/container.conf /etc/opt/microsoft/omsagent/conf/omsagent.d/container.conf;
CMD [ "/root/main.sh" ]
