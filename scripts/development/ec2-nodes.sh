#!/bin/bash

##############################################################################
#
# This script is used to return a list of nodes in the resourcejson Rundeck 
# format.
# The list is obtained by querying AWS with the aws ec2 describe-instances command 
# and relies on identifying the instances by filtering on tags.
# 
# It is intended to be used as part of a script "node source" within Rundeck and requires
# 5 parameters, as described in the usage text below.
###############################################################################

if [ "$#" -ne 5 ]
then
    echo "Incorrect number of arguments supplied"
    echo 
    echo "Usage: ec2-nodes.sh <domain name suffix> <username> <path to key> <filter tags> <name tag>"
    echo "<domain name suffix> is a domain that is added to the returned name so that it is resolvable on the network - e.g. .myawsnetwork.com"
    echo "<username> the user that Rundeck will use when connecting to the node via SSH"
    echo "<path to key> is the Rundeck key storage path for the key to use when connecting via SSH"
    echo "<filter tags> is a list of tag/value pairs that should be used for filtering the results, pipe separated - e.g. Service=CHIPS|config-base-path=*chips-e2e-configs"
    echo "<name tag> is the instance tag to use for the returned node name - e.g. Name"
    exit 1
fi

DOMAIN_NAME_SUFFIX=$1
USERNAME=$2
KEY_PATH=$3
FILTER_TAGS=$4
NAME_TAG=$5

# Split out tags param and generate a filter for use with the aws cli
OLDIFS=${IFS}
IFS=\|
for TAG_VALUE_PAIR in ${FILTER_TAGS}
do
  TAG=${TAG_VALUE_PAIR%%=*}
  VALUE=${TAG_VALUE_PAIR##*=}
  AWS_CLI_FILTER="${AWS_CLI_FILTER} Name=tag:${TAG},Values=${VALUE}"
done
IFS=${OLDIFS}

# Call the aws cli to get a list of nodes
E2E_INSTANCES=$(aws ec2 describe-instances --region eu-west-2 --filters ${AWS_CLI_FILTER} | jq -r '.Reservations[].Instances[].Tags[] | select(.Key=="'${NAME_TAG}'").Value')

# Populate json output containing each instance
echo -n "["
FIRST=1
for INSTANCE in ${E2E_INSTANCES}
do
  if [[ FIRST -eq 0 ]]; then
    echo ","
  else
    FIRST=0
  fi

  echo -n "{
    \"nodename\":\"${INSTANCE}\",
    \"hostname\":\"${INSTANCE}${DOMAIN_NAME_SUFFIX}\",
    \"username\":\"${USERNAME}\",
    \"tags\":\"${INSTANCE}\",
    \"ssh-key-storage-path\":\"${KEY_PATH}\"
  }"
done
echo "]"
