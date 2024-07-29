#!/bin/bash

# . config.sh
docker system prune -f
rsync -v -a -x -u -H -S -i -P \
        --exclude '.idea' \
        --exclude '.git' \
        --exclude '.DS_Store' \
        --exclude  '.metadata' \
        --exclude  'master.zip' \
        /data/lake/cloneid/git \
        /data/lake/cloneid/module3/docker/v1
exit
ssh -i ~/.ssh/id_intra \
    -o "UserKnownHostsFile=/dev/null" \
    -o StrictHostKeychecking=no  \
    root@172.18.0.3 \
    "cd /data/lake/cloneid/module3/cloneid;  make -f scripts/Makefile;  make -f scripts/Makefile test"
    
