#!/bin/bash

export DIR0=$(dirname $0)

source "${DIR0}/functions.sh"

startup

echo DIR0=${DIR0}
echo $EXEBASETC awaiting DB warmup

sleep 5

process_unit "collect"
