TMPDIR="/opt"
cd $TMPDIR
wget https://github.com/Microsoft/OMS-Agent-for-Linux/releases/download/OMSAgent_GA_v1.4.4-210/omsagent-1.4.4-210.universal.x64.sh 
wget https://vishwasstorageaccount.blob.core.windows.net/dockerprovider0306/docker-cimprov-1.0.0-31.universal.x86_64.sh
wget https://keikostorage.blob.core.windows.net/keikostorage/omi-1.4.2-34.ssl_100.ulinux.x64.deb
chmod 775 $TMPDIR/*.sh

$TMPDIR/omsagent-*.universal.x64.sh --extract
mv $TMPDIR/omsbundle* $TMPDIR/omsbundle

# install the fixed OMI first than install SCX
/usr/bin/dpkg -i $TMPDIR/omi*.deb

$TMPDIR/omsbundle/bundles/scx-1.6.*-*.universal.x64.sh --install
/usr/bin/dpkg -i $TMPDIR/omsbundle/100/omsagent*.deb
/usr/bin/dpkg -i $TMPDIR/omsbundle/100/omsconfig*.deb
#/$TMPDIR/omsbundle/oss-kits/docker-cimprov-1.0.0-*.x86_64.sh --install
#Use downloaded docker-provider instead of the bundled one
/$TMPDIR/docker-cimprov-1.0.0-*.x86_64.sh --install
rm -rf $TMPDIR/omsbundle
rm -f $TMPDIR/omsagent*.sh
rm -f $TMPDIR/docker-cimprov*.sh
rm -f $TMPDIR/omi*.deb
