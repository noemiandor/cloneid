#!/bin/bash

docker/build.sh base
docker/build.sh utils
docker/build.sh reference
docker/build.sh unit0

