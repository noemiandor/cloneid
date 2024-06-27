#!/bin/bash

cd /root/node

export PAYLOADDIR="/opt/lake/data/cloneid/module02/data/jobs/"
export PAYLOADQUEUE="waiting"
export QUEUEDONE="done"


export DATALKE_DIR='/opt/lake/data/cloneid/module02/data/'
export FIDINFO_DIR='/opt/lake/data/cloneid/module02/data/fids/'
export JOBINFO_DIR='/opt/lake/data/cloneid/module02/data/jobs/'
export SPSTATS_DIR='/opt/lake/data/cloneid/module02/data/files/spstats/'
export CELLPOS_DIR='/opt/lake/data/cloneid/module02/data/files/cellpose/'


pm2 kill
pm2 kill
pm2 start dw.mjs
pm2 logs
