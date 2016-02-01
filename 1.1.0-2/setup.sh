wget https://github.com/Microsoft/OMS-Agent-for-Linux/releases/download/v1.1.0-2/omsagent-1.1.0-2.universal.x64.sh
chmod 775 /root/*.sh
/root/omsagent-1.1.0-2.universal.x64.sh --extract
mv /root/omsbundle* /root/omsbundle
/usr/bin/dpkg -i /root/omsbundle/100/omi*.deb
/usr/bin/dpkg -i /root/omsbundle/100/scx*.deb
/usr/bin/dpkg -i /root/omsbundle/100/omsagent*.deb
/usr/bin/dpkg -i /root/omsbundle/100/omsconfig*.deb
/root/docker-cimprov-1.0.0-0.universal.x86_64.sh --install
rm -rf /root/omsbundle
rm -f /root/omsagent*.sh
rm -f /root/*.deb
