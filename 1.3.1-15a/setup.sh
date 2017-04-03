TMPDIR="/opt"
cd $TMPDIR
wget https://keiko.blob.core.windows.net/container/omsagent-1.3.1-15.universal.x64.sh
chmod 775 $TMPDIR/*.sh
$TMPDIR/omsagent-1.3.1-*.universal.x64.sh --extract
mv $TMPDIR/omsbundle* $TMPDIR/omsbundle
/usr/bin/dpkg -i $TMPDIR/omsbundle/100/omi*.deb
/usr/bin/dpkg -i $TMPDIR/omsbundle/100/scx*.deb
/usr/bin/dpkg -i $TMPDIR/omsbundle/100/omsagent*.deb
/usr/bin/dpkg -i $TMPDIR/omsbundle/100/omsconfig*.deb
/$TMPDIR/omsbundle/oss-kits/docker-cimprov-1.0.0-*.x86_64.sh --install
rm -rf $TMPDIR/omsbundle
rm -f $TMPDIR/omsagent*.sh
rm -f $TMPDIR/*.deb
