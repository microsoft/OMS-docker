TMPDIR="/opt"
cd $TMPDIR
#wget https://github.com/Microsoft/OMS-Agent-for-Linux/releases/download/v1.1.0-239/omsagent-1.1.0-239.universal.x64.sh
wget https://atlantapublicint2.blob.core.windows.net:443/resources/omsagent-1.2.0-0.universal.x64.sh 
chmod 775 $TMPDIR/*.sh
$TMPDIR/omsagent-1.2.0-0.universal.x64.sh --extract
mv $TMPDIR/omsbundle* $TMPDIR/omsbundle
/usr/bin/dpkg -i $TMPDIR/omsbundle/100/omi*.deb
/usr/bin/dpkg -i $TMPDIR/omsbundle/100/scx*.deb
/usr/bin/dpkg -i $TMPDIR/omsbundle/100/omsagent*.deb
/usr/bin/dpkg -i $TMPDIR/omsbundle/100/omsconfig*.deb
/$TMPDIR/omsbundle/oss-kits/docker-cimprov-1.0.0-9universal.x86_64.sh --install
rm -rf $TMPDIR/omsbundle
rm -f $TMPDIR/omsagent*.sh
rm -f $TMPDIR/*.deb
