TMPDIR="/opt"
cd $TMPDIR

wget https://github.com/microsoft/OMS-Agent-for-Linux/releases/download/OMSAgent_v1.13.40-0/omsagent-1.13.40-0.universal.x64.sh

#create file to disable omi service startup script
touch /etc/.omi_disable_service_control
wget https://github.com/microsoft/Docker-Provider/releases/download/v1.0.0-39/docker-cimprov-1.0.0-39.universal.x86_64.sh
chmod 775 $TMPDIR/*.sh

#Extract omsbundle
$TMPDIR/omsagent-*.universal.x64.sh --extract
mv $TMPDIR/omsbundle* $TMPDIR/omsbundle

#Install omi
/usr/bin/dpkg -i $TMPDIR/omsbundle/110/omi*.deb

#Install scx
/usr/bin/dpkg -i $TMPDIR/omsbundle/110/scx*.deb
#$TMPDIR/omsbundle/bundles/scx-1.6.*-*.universal.x64.sh --install

#Install omsagent and omsconfig

/usr/bin/dpkg -i $TMPDIR/omsbundle/110/omsagent*.deb

/usr/bin/dpkg -i $TMPDIR/omsbundle/110/omsconfig*.deb
#/$TMPDIR/omsbundle/oss-kits/docker-cimprov-1.0.0-*.x86_64.sh --install
#Use downloaded docker-provider instead of the bundled one

/$TMPDIR/docker-cimprov-1.0.0-*.x86_64.sh --install

rm -rf $TMPDIR/omsbundle
rm -f $TMPDIR/omsagent*.sh
rm -f $TMPDIR/docker-cimprov*.sh
