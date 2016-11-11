HOSTNAME=`cat /mnt/etc/hostname`
TMPDIR="/opt"
cd $TMPDIR
#wget https://github.com/Microsoft/OMS-Agent-for-Linux/releases/download/OMSAgent-201611-v1.2.1-148/omsagent-1.2.1-148.universal.x64.sh
wget https://scadvisorcontent.blob.core.windows.net/resources/omsagent-1.2.1-148.universal.x64.sh
chmod 775 $TMPDIR/*.sh
$TMPDIR/omsagent-1.2.1-148.universal.x64.sh --extract
mv $TMPDIR/omsbundle* $TMPDIR/omsbundle
/usr/bin/dpkg -i $TMPDIR/omsbundle/100/omi*.deb
/usr/bin/dpkg -i $TMPDIR/omsbundle/100/scx*.deb
/usr/bin/dpkg -i $TMPDIR/omsbundle/100/omsagent*.deb
/usr/bin/dpkg -i $TMPDIR/omsbundle/100/omsconfig*.deb
/$TMPDIR/omsbundle/oss-kits/docker-cimprov-1.0.0-*.x86_64.sh --install
rm -rf $TMPDIR/omsbundle
rm -f $TMPDIR/omsagent*.sh
rm -f $TMPDIR/*.deb

