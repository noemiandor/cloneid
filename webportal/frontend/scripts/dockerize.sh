#!/bin/bash

#BUILD
docker build --platform linux/amd64 -t cloneid-module1a:latest --build-arg BUILD_INFO="Clonid Module1/Moffitt/contract" --build-arg BUILD_DATE=$(date +"%Y%m%d%H%M%S") --build-arg BUILD_VERSION="1.0" --build-arg BUILD_ARCH="amd64" -f Dockerfile .

#RUN
#docker run --rm --name=cloneid-module1:latest -p 4173:4173 cloneid-module1
