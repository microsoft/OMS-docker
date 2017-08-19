TMPDIR="/opt"
cd $TMPDIR
wget https://github.com/Microsoft/OMS-Agent-for-Linux/releases/download/OMSAgent_GA_v1.4.0-45/omsagent-1.4.0-45.universal.x64.sh
wget https://samisstorage.blob.core.windows.net/dockerproviderreleases/docker-cimprov-1.0.0-27.universal.x86_64.sh
chmod 775 $TMPDIR/*.sh

$TMPDIR/omsagent-*.universal.x64.sh --extract
mv $TMPDIR/omsbundle* $TMPDIR/omsbundle
$TMPDIR/omsbundle/bundles/scx-1.6.*-*.universal.x64.sh --install
/usr/bin/dpkg -i $TMPDIR/omsbundle/100/omsagent*.deb
/usr/bin/dpkg -i $TMPDIR/omsbundle/100/omsconfig*.deb

#Upgrade OMI
wget http://packages.microsoft.com/config/ubuntu/14.04/packages-microsoft-prod.deb
dpkg -i packages-microsoft-prod.deb
apt-get update
apt-get install -y apt-transport-https
apt-get update
apt-get upgrade -y omi

#/$TMPDIR/omsbundle/oss-kits/docker-cimprov-1.0.0-*.x86_64.sh --install
#Use downloaded docker-provider instead of the bundled one
/$TMPDIR/docker-cimprov-1.0.0-*.x86_64.sh --install
rm -rf $TMPDIR/omsbundle
rm -f $TMPDIR/omsagent*.sh
rm -f $TMPDIR/docker-cimprov*.sh