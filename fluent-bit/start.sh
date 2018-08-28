#!/usr/bin/env sh

echo $SHELL
now=$(date +"%Y%m%d-%H%m%s")
LOGFILE="/shared/data/fluent-bit-startup.$now.log"
echo "`date +%H:%M:%S`  Checking for required files  in shared volume" >> $LOGFILE
while [ ! -f /shared/data/workspaceId ] || [ ! -f /shared/data/oms.key ] || [ ! -f /shared/data/oms.crt ]
do
        echo "`date +%H:%M:%S`  Required files not found in shared volume" >> $LOGFILE
        sleep 2
done
echo "`date +%H:%M:%S`  All required file present in shared volume" >> $LOGFILE

# This is for testing
# echo "`date +%H:%M:%S`  Removing fluent-bit logs database" >> $LOGFILE
# rm -rf /var/log/fblogs.db

/fluent-bit/bin/fluent-bit -c /fluent-bit/etc/fluent-bit.conf \
                           -e /fluent-bit/bin/out_oms.so "$@"