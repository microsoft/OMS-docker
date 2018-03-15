<<<<<<< HEAD
TMPDIR="/opt"
cd $TMPDIR
#wget https://github.com/Microsoft/OMS-Agent-for-Linux/releases/download/OMSAgent_GA_v1.4.1-45/omsagent-1.4.1-45.universal.x64.sh
wget https://keikostorage.blob.core.windows.net/keikostorage/omsagent-1.5.1-253.universal.x64.sh
#create file to disable omi service startup script
touch /etc/.omi_disable_service_control

#wget https://github.com/Microsoft/OMS-Agent-for-Linux/releases/download/OMSAgent_GA_v1.4.1-123/omsagent-1.4.1-123.universal.x64.sh
wget https://vishwasstorageaccount.blob.core.windows.net/dockerprovider0312/docker-cimprov-1.0.0-31.universal.x86_64.sh 
chmod 775 $TMPDIR/*.sh

#Install omi
/usr/bin/dpkg -i $TMPDIR/omi*.deb

#Do further install
#Extract omsbundle
$TMPDIR/omsagent-*.universal.x64.sh --extract
mv $TMPDIR/omsbundle* $TMPDIR/omsbundle
#Install scx
$TMPDIR/omsbundle/bundles/scx-1.6.*-*.universal.x64.sh --install
#Install omsagent and omsconfig
/usr/bin/dpkg -i $TMPDIR/omsbundle/100/omsagent*.deb
/usr/bin/dpkg -i $TMPDIR/omsbundle/100/omsconfig*.deb

#/$TMPDIR/omsbundle/oss-kits/docker-cimprov-1.0.0-*.x86_64.sh --install
#Use downloaded docker-provider instead of the bundled one
/$TMPDIR/docker-cimprov-1.0.0-*.x86_64.sh --install
rm -rf $TMPDIR/omsbundle
rm -f $TMPDIR/omsagent*.sh
rm -f $TMPDIR/docker-cimprov*.sh
=======
TMPDIR="/opt"
cd $TMPDIR 
wget https://keikostorage.blob.core.windows.net/keikostorage/omsagent-1.5.1-253.universal.x64.sh 
wget https://vishwasstorageaccount.blob.core.windows.net/dockerprovider0312/docker-cimprov-1.0.0-31.universal.x86_64.sh 
chmod 775 $TMPDIR/*.sh

$TMPDIR/omsagent-*.universal.x64.sh --extract 
mv $TMPDIR/omsbundle* $TMPDIR/omsbundle 
$TMPDIR/omsbundle/bundles/scx-1.6.*-*.universal.x64.sh --extract 
mv $TMPDIR/omsbundle/bundles/scxbundle* $TMPDIR/omsbundle/bundles/scxbundle 
/usr/bin/dpkg -i $TMPDIR/omsbundle/bundles/scxbundle/100/omi*.deb 
$TMPDIR/omsbundle/bundles/scx-1.6.*-*.universal.x64.sh --install
/usr/bin/dpkg -i $TMPDIR/omsbundle/100/omsagent*.deb
/usr/bin/dpkg -i $TMPDIR/omsbundle/100/omsconfig*.deb
#/$TMPDIR/omsbundle/oss-kits/docker-cimprov-1.0.0-*.x86_64.sh --install
#Use downloaded docker-provider instead of the bundled one
/$TMPDIR/docker-cimprov-1.0.0-*.x86_64.sh --install
rm -rf $TMPDIR/omsbundle
rm -f $TMPDIR/omsagent*.sh
rm -f $TMPDIR/docker-cimprov*.sh
>>>>>>> 1d63f1a2b59a0edb6896a47c9f237093d7b9b9fa
