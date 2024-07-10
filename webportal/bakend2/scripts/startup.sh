#!/bin/bash

/root/scripts/apply_patch.sh
/root/scripts/buildcloneid.sh

service ssh restart
service cron restart

source /root/scripts/exports.sh

cd /root/node

env|grep _DIR
env|grep QUEUE

pm2 kill
pm2 start dw.mjs
pm2 logs