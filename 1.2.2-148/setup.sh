TMPDIR="/opt"
cd $TMPDIR
wget https://atlantapublicint2.blob.core.windows.net:443/resources/omsagent-1.2.2-148.universal.x64.sh
sed -i "s/^exit 101$/exit 0/" /usr/sbin/policy-rc.d
chmod 775 $TMPDIR/*.sh
$TMPDIR/omsagent-1.2.2-148.universal.x64.sh --extract
mv $TMPDIR/omsbundle* $TMPDIR/omsbundle
/usr/bin/dpkg -i $TMPDIR/omsbundle/100/omi*.deb
/usr/bin/dpkg -i $TMPDIR/omsbundle/100/scx*.deb
/usr/bin/dpkg -i $TMPDIR/omsbundle/100/omsagent*.deb
/usr/bin/dpkg -i $TMPDIR/omsbundle/100/omsconfig*.deb
/$TMPDIR/omsbundle/oss-kits/docker-cimprov-1.0.0-*.x86_64.sh --install
rm -rf $TMPDIR/omsbundle
rm -f $TMPDIR/omsagent*.sh
rm -f $TMPDIR/*.deb
