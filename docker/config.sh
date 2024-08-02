#!/bin/bash

export PLATFORM=amd64
export BUILDPLATFORM='linux/amd64'
export IMAGE_BUILD_ARCH=amd64
export IMAGE_BUILD_INFO="Cloneid Module3"
export IMAGE_BUILD_NAME="cloneid-module3"
export IMAGE_BUILD_DATE=`date -u +"%Y-%m-%d"`
export IMAGE_BUILD_VERSION="1.0𝛂"
export IMAGE_BUILD_REVISION=`echo $IMAGE_BUILD_DATE | sha1sum|cut -d ' ' -f 1`
export IMAGE_AUTHOR_FNAME="Daniel"
export IMAGE_AUTHOR_LNAME="Hannaby"
export IMAGE_AUTHOR_EMAIL="<legwork_02land@icloud.com>"
export IMAGE_VENDOR="Moffitt"
export IMAGE_LICENSE="MIT"
export IMAGE_TITLE="${IMAGE_BUILD_NAME}:latest"
export PHASE="p1"

export CLONEID_URL_WEB="https://www.cloneredesign.com"
export CLONEID_URL_GIT="https://github.com/noemiandor/cloneid"
export CLONEID_GIT="$(cd ../..; pwd)"
export CLONEID_GIT="$(pwd)"
export CLONEID_HOME="${CLONEID_GIT}"
export CLONEID_URL_ZIP="${CLONEID_URL_GIT}/archive/refs/heads/master.zip"
export CLONEID_TAR=cloneid_1.2.1.tar.gz

export CLONEID_MODULE3_PERFORMANCE_TEST_DIR="$(pwd)/docker/v1/test/performance"
export CLONEID_MODULE3_PERFORMANCE_TEST_REFERENCE=${CLONEID_MODULE3_PERFORMANCE_TEST_DIR}/bin/sh/reference.sh
export CLONEID_MODULE3_PERFORMANCE_TEST_UNIT0=${CLONEID_MODULE3_PERFORMANCE_TEST_DIR}/bin/sh/unit0.sh
export CLONEID_MODULE3_PERFORMANCE_TEST_TEST=${CLONEID_MODULE3_PERFORMANCE_TEST_DIR}/bin/sh/test.sh
