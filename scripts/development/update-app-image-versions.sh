#!/bin/bash

##############################################################################
#
# This script updates the app-image-versions file for a specific dev environment.
#
# The script expects three arguments:
# - name of the environmnet (e.g. cidev)
# - chips-app image version in ECR (e.g. 74b9ae4)
# - chips-apache image version in ECR (e.g. 74b9ae4)
#
# The script also expects the DEV_CONFIG_BUCKET_AND_PATH env var to be set.
#
###############################################################################

if [ "$#" -ne 3 ]
then
  echo "Invalid number of arguments - expected three arguments: <env name> <chips-app image version> <chips-apache image version>"
  exit 1
fi

ENV_NAME=$1
CHIPS_APP_VERSION=$2
CHIPS_APACHE_VERSION=$3

# Set up TMP folder specific to this script and environment
TMP=/var/tmp/update-app-image-versions/${ENV_NAME}
mkdir -p ${TMP} 

S3_VERSION_FILE=s3://${DEV_CONFIG_BUCKET_AND_PATH}/${ENV_NAME}/app-image-versions
LOCAL_VERSION_FILE=${TMP}/app-image-versions

# Download the existing file from S3
aws s3 cp ${S3_VERSION_FILE} ${TMP}

# Modify the downloaded file
sed -i "s/chips-app:.*/chips-app:${CHIPS_APP_VERSION}/" ${LOCAL_VERSION_FILE}
sed -i 's/chips-apache:.*/chips-apache:'${CHIPS_APACHE_VERSION}'/' ${LOCAL_VERSION_FILE}

echo "New ${LOCAL_VERSION_FILE}:"
cat ${LOCAL_VERSION_FILE}

# Upload the modified file back to S3
aws s3 cp ${LOCAL_VERSION_FILE} ${S3_VERSION_FILE}

# Clean up
rm -f ${LOCAL_VERSION_FILE}
