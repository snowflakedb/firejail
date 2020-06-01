#!/bin/bash -e
#
# Copyright (c) 2020 Snowflake Computing Inc. All right reserved.
#
#

function usage()
{
    echo "usage: ./build_and_publish_rpm.sh [S3_BUCKET_BASE_URL] [PRIVATE_KEY_FILE]"
    exit 1
}

if [ "$#" -ne 2 ]; then
  usage
fi


THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $THIS_DIR/version.sh
S3_BUCKET_BASE_URL=${1%/}
PRIVATE_KEY_FILE=$2

$THIS_DIR/../platform/rpm/mkrpm.sh firejail $FIREJAIL_SF_VERSION \
    "--disable-userns --disable-contrib-install --disable-file-transfer --disable-x11 --disable-firetunnel"

PACKAGE_NAME=$(ls -1 -- firejail-${FIREJAIL_SF_VERSION}-1.x86_64.rpm)

if [[ -z $PACKAGE_NAME ]]; then
  echo "ERROR: RPM package not found"
  exit 1
fi

openssl dgst -sha256 -sign $PRIVATE_KEY_FILE -out ${PACKAGE_NAME}.sig $PACKAGE_NAME

aws s3 cp $PACKAGE_NAME $S3_BUCKET_BASE_URL/firejail/$FIREJAIL_SF_VERSION/
aws s3 cp ${PACKAGE_NAME}.sig $S3_BUCKET_BASE_URL/firejail/$FIREJAIL_SF_VERSION/
