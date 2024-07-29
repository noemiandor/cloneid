#!/bin/bash

source config.sh

IMAGE_BUILD_NAME="cloneid-module3"

if [ ! -z "$1" ]; then
    OPTION=$(echo $1 | tr '[:upper:]' '[:lower:]')
    IMAGE_BUILD_NAME_WITH_OPTIONS="${IMAGE_BUILD_NAME}-${OPTION}"
    if [ ! -f Dockerfile_${IMAGE_BUILD_NAME_WITH_OPTIONS} ]; then
        echo "No Dockerfile_${IMAGE_BUILD_NAME_WITH_OPTIONS} found. Exiting..."
    fi
    IMAGE_BUILD_NAME="${IMAGE_BUILD_NAME}-${OPTION}"

    docker system prune -f
    docker run --rm -ti --name ${IMAGE_BUILD_NAME} -v ${CLONEID_MODULE3_PERFORMANCE_TEST_DIR}:${CLONEID_MODULE3_PERFORMANCE_TEST_DIR} ${IMAGE_BUILD_NAME}-${IMAGE_BUILD_ARCH}:latest
fi
