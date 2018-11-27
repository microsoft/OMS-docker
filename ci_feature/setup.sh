TMPDIR="/opt"
cd $TMPDIR

#Download utf-8 encoding capability on the omsagent container.

apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y locales

sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8

wget https://github.com/Microsoft/OMS-Agent-for-Linux/releases/download/OMSAgent_v1.6.0-163/omsagent-1.6.0-163.universal.x64.sh

#create file to disable omi service startup script
touch /etc/.omi_disable_service_control
wget https://dockerprovider.blob.core.windows.net/cifeature/docker-cimprov-3.0.0-2.universal.x86_64.sh

chmod 775 $TMPDIR/*.sh

#Extract omsbundle
$TMPDIR/omsagent-*.universal.x64.sh --extract
mv $TMPDIR/omsbundle* $TMPDIR/omsbundle
#Install omi
/usr/bin/dpkg -i $TMPDIR/omsbundle/100/omi*.deb

#Install scx
/usr/bin/dpkg -i $TMPDIR/omsbundle/100/scx*.deb
#$TMPDIR/omsbundle/bundles/scx-1.6.*-*.universal.x64.sh --install

#Install omsagent and omsconfig

/usr/bin/dpkg -i $TMPDIR/omsbundle/100/omsagent*.deb
/usr/bin/dpkg -i $TMPDIR/omsbundle/100/omsconfig*.deb

#Assign permissions to omsagent user to access docker.sock
sudo apt-get install acl
sudo setfacl -m user:omsagent:rw /var/run/docker.sock

#/$TMPDIR/omsbundle/oss-kits/docker-cimprov-1.0.0-*.x86_64.sh --install
#Use downloaded docker-provider instead of the bundled one

/$TMPDIR/docker-cimprov-3.0.0-*.x86_64.sh --install

#download and install fluent-bit(td-agent-bit)
wget -qO - https://packages.fluentbit.io/fluentbit.key | sudo apt-key add -
sudo echo "deb https://packages.fluentbit.io/ubuntu/xenial xenial main" >> /etc/apt/sources.list  
sudo apt-get update
sudo apt-get install td-agent-bit=0.13.7 sqlite3=3.11.0-1ubuntu1 libsqlite3-dev=3.11.0-1ubuntu1 -y

rm -rf $TMPDIR/omsbundle
rm -f $TMPDIR/omsagent*.sh
rm -f $TMPDIR/docker-cimprov*.sh
