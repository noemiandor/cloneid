#!/bin/bash
cat $1| while IFS= read -r line; do echo $line; sleep 0.2; done