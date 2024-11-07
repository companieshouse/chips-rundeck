#!/bin/bash

##############################################################################
#
# This script updates the app-image-versions file for a specific dev environment.
#
# The script expects three arguments:
# - name of the environment (e.g. cidev)
# - chips-app image version in ECR (e.g. develop-74b9ae4)
# - chips-apache image version in ECR (e.g. develop-74b9ae4)
#
# The script also expects the DEV_CONFIG_BUCKET and DEV_CONFIG_BUCKET_ENV_PATH env vars to be set.
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

S3_VERSION_FILE=s3://${DEV_CONFIG_BUCKET}/${DEV_CONFIG_BUCKET_ENV_PATH}/${ENV_NAME}/app-image-versions
LOCAL_VERSION_FILE=${TMP}/app-image-versions

# Check if the environment specific app-image-versions file exists
aws s3api head-object --bucket ${DEV_CONFIG_BUCKET} --key ${DEV_CONFIG_BUCKET_ENV_PATH}/${ENV_NAME}/app-image-versions > /dev/null 2>&1 || NO_VERSION_FILE=true
if [ ${NO_VERSION_FILE} ]; then
  echo "Environment specific file not found at ${S3_VERSION_FILE} - creating one from s3://${DEV_CONFIG_BUCKET}/${DEV_CONFIG_BUCKET_ENV_PATH}/app-image-versions"
  # Download the template file from S3
  aws s3 cp s3://${DEV_CONFIG_BUCKET}/${DEV_CONFIG_BUCKET_ENV_PATH}/app-image-versions ${TMP}
else
  # Download the existing file from S3
  aws s3 cp ${S3_VERSION_FILE} ${TMP}
fi

# Modify the downloaded file to update the chips-app and chips-apache versions
sed -i "s/chips-app:.*/chips-app:${CHIPS_APP_VERSION}/" ${LOCAL_VERSION_FILE}
sed -i 's/chips-apache:.*/chips-apache:'${CHIPS_APACHE_VERSION}'/' ${LOCAL_VERSION_FILE}

echo "New ${LOCAL_VERSION_FILE}:"
cat ${LOCAL_VERSION_FILE}

# Upload the modified file back to S3
aws s3 cp ${LOCAL_VERSION_FILE} ${S3_VERSION_FILE}

# Clean up
rm -f ${LOCAL_VERSION_FILE}
