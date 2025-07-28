#!/bin/bash

##############################################################################
#
# This script checks to see if chips is running and returning a 200 HTTP code 
# in a specific E2E environment via the local listen address.
# If the status code is not 200 then the script will retry until the supplied timeout 
# is exceeded or 200 is returned.
#
# The script expects three arguments:
# - name of the environment (e.g. cidev)
# - timeout in seconds - i.e. how long to keep trying before exiting with a failure code
# - the listen port
#
#
###############################################################################

if [ "$#" -ne 3 ]
then
  echo "Invalid number of arguments - expected three arguments: <env name> <timeout> <port>"
  exit 1
fi

ENV_NAME=$1
TIMEOUT=$2
PORT=$3

CHIPS_CHECK_URL="http://127.0.0.1:${PORT}/chips/cff"
echo "Checking connection to ${ENV_NAME} using ${CHIPS_CHECK_URL}"

HTTP_STATUS=""
while [[ ${HTTP_STATUS} != "200" ]]
do
  CURL_OUTPUT=$(curl -k -m 10 -s -I -X GET "${CHIPS_CHECK_URL}")
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
      exit 1
    fi
  fi
done
