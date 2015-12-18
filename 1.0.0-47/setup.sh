wget https://github.com/MSFTOSSMgmt/OMS-Agent-for-Linux/releases/download/1.0.0-47/omsagent-1.0.0-47.universal.x64.sh
chmod 775 /root/*.sh
/root/omsagent-1.0.0-47.universal.x64.sh --extract
mv /root/omsbundle* /root/omsbundle
/usr/bin/dpkg -i /root/omsbundle/100/omi*.deb
/usr/bin/dpkg -i /root/omsbundle/100/scx*.deb
/usr/bin/dpkg -i /root/omsbundle/100/omsagent*.deb
/usr/bin/dpkg -i /root/omsbundle/100/omsconfig*.deb
#/root/omsbundle/oss-kits/docker-cimprov-0.1.0-0.universal.x86_64.sh --install
rm -rf /root/omsbundle
rm -f /root/omsagent*.sh
rm -f /root/*.deb
