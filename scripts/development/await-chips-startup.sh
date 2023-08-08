#!/bin/bash

##############################################################################
#
# This script checks to see if chips is running and returning a 200 HTTP code 
# in a specific dev environment.
# If the status code is not 200 then the script will retry until the supplied timeout 
# is exceeded or 200 is returned.
#
# The script expects two arguments:
# - name of the environment (e.g. cidev)
# - timeout in seconds - i.e. how long to keep trying before exiting with a failure code
#
# The script also expects the DEV_CONFIG_BUCKET_AND_PATH and 
# DEV_CHIPS_BASE_URL env vars to be set.
#
###############################################################################

if [ "$#" -ne 2 ]
then
  echo "Invalid number of arguments - expected three arguments: <env name> <timeout>"
  exit 1
fi

ENV_NAME=$1
TIMEOUT=$2

# Set up TMP folder specific to this script and environment
TMP=/var/tmp/await-chips-startup/${ENV_NAME}
mkdir -p ${TMP} 

S3_VERSION_FILE=s3://${DEV_CONFIG_BUCKET_AND_PATH}/${ENV_NAME}/app-image-versions
LOCAL_VERSION_FILE=${TMP}/app-image-versions

# Download the existing file from S3
aws s3 cp ${S3_VERSION_FILE} ${TMP}

# Source the file so we can work out which port to connect to
. ${LOCAL_VERSION_FILE} 
CHIPS_CHECK_URL="${DEV_CHIPS_BASE_URL}:2${APP_INSTANCE_NUMBER}00/chips/cff"

HTTP_STATUS=""
while [[ ${HTTP_STATUS} != "200" ]]
do
  CURL_OUTPUT=$(curl -m 10 -s -I -X GET "${CHIPS_CHECK_URL}")
  CURL_EXIT_CODE=$?

  if [[ ${CURL_EXIT_CODE} = "28" ]]
  then
    echo "Timeout connecting to ${ENV_NAME} using ${CHIPS_CHECK_URL}"
  else
    HTTP_STATUS=$(echo ${CURL_OUTPUT} | head -1 | awk '{print $2}')
    echo "HTTP_STATUS=${HTTP_STATUS}"
  fi
  
  if [[ ${HTTP_STATUS} != "200" ]]
  then
    if [[ ${SECONDS} -lt ${TIMEOUT} ]]
    then
      sleep 10
    else
      echo "Timed out after ${TIMEOUT} seconds"
      rm -f ${LOCAL_VERSION_FILE}
      exit 1
    fi
  fi
done

# Clean up
rm -f ${LOCAL_VERSION_FILE}
