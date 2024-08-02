#!/bin/bash

DIR0=$(dirname $0)

. ${DIR0}/config.sh

while [ ! -z "$1" ]; do

    IMAGE_BUILD_NAME="cloneid-module3-${PHASE}"

    OPTION=$(echo $1 | tr '[:upper:]' '[:lower:]')
    IMAGE_BUILD_NAME_WITH_OPTIONS="${IMAGE_BUILD_NAME}-${OPTION}"
    IMAGE_BUILD_INFO=$(echo $(echo ${IMAGE_BUILD_NAME} |tr '-' ' ') $OPTION | sed -r 's/\<./\U&/g')
    IMAGE_BUILD_NAME="${IMAGE_BUILD_NAME}-${OPTION}"

    echo -e "\n########################################################"
    echo "Building image: ${IMAGE_BUILD_NAME}-${IMAGE_BUILD_ARCH}..."
    echo "Image build Info: ${IMAGE_BUILD_INFO}..."

    # docker system prune -f
    # echo \
    docker build -f ${DIR0}/v1/Dockerfiles/Dockerfile_${IMAGE_BUILD_NAME} -t ${IMAGE_BUILD_NAME}-${IMAGE_BUILD_ARCH}:latest \
        --platform="${BUILDPLATFORM}" \
        --build-arg="IMAGE_BUILD_ARCH=amd64" \
        --build-arg="IMAGE_BUILD_INFO=${IMAGE_BUILD_INFO}" \
        --build-arg="IMAGE_BUILD_VERSION=${IMAGE_BUILD_VERSION}" \
        --build-arg="IMAGE_BUILD_REVISION=${IMAGE_BUILD_REVISION}" \
        --build-arg="IMAGE_BUILD_NAME=${IMAGE_BUILD_NAME}" \
        --build-arg="IMAGE_BUILD_DATE=${IMAGE_BUILD_DATE}" \
        --build-arg="IMAGE_AUTHOR_FNAME=${IMAGE_AUTHOR_FNAME}" \
        --build-arg="IMAGE_AUTHOR_LNAME=${IMAGE_AUTHOR_LNAME}" \
        --build-arg="IMAGE_AUTHOR_EMAIL=${IMAGE_AUTHOR_EMAIL}" \
        --build-arg="IMAGE_VENDOR=${IMAGE_VENDOR}" \
        --build-arg="IMAGE_LICENSE=${IMAGE_LICENSE}" \
        --build-arg="IMAGE_TITLE=${IMAGE_TITLE}" \
        --build-arg="CLONEID_URL_WEB=${CLONEID_URL_WEB}" \
        --build-arg="CLONEID_URL_GIT=${CLONEID_URL_GIT}" \
        --build-arg="CLONEID_URL_ZIP=${CLONEID_URL_ZIP}" \
        --build-arg="CLONEID_TAR=${CLONEID_TAR}" \
        --build-arg="CLONEID_HOME=${CLONEID_HOME}" \
        --build-arg="CLONEID_GIT=${CLONEID_GIT}" \
        --build-arg="JAVA_PACKAGE=${JAVA_PACKAGE}" \
        --build-arg="JAVA_HOME=${JAVA_HOME}" \
        --build-arg="CLONEID_MODULE3_PERFORMANCE_TEST_DIR=${CLONEID_MODULE3_PERFORMANCE_TEST_DIR}" \
        --build-arg="CLONEID_MODULE3_PERFORMANCE_TEST_REFERENCE=${CLONEID_MODULE3_PERFORMANCE_TEST_REFERENCE}" \
        --build-arg="CLONEID_MODULE3_PERFORMANCE_TEST_UNIT0=${CLONEID_MODULE3_PERFORMANCE_TEST_UNIT0}" \
        --build-arg="CLONEID_MODULE3_PERFORMANCE_TEST_TEST=${CLONEID_MODULE3_PERFORMANCE_TEST_TEST}" \
        .

    echo -e "Image build complete"
    echo -e "########################################################\n"

    shift 

done
