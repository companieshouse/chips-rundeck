#!/bin/bash

##############################################################################
#
# This script removes a listener rule from an existing CHIPS ALB that was
# previously added to redirect any requests matching the path /chips/cff* to 
# /maintenance.
#
# The script expects a single argument that is the name of the ALB, and uses
# that name to find the ALB and then search for the listener on port 443. It
# then removes the rule if it exists.
#
###############################################################################

if [ "$#" -ne 1 ]
then
  echo "Invalid number of arguments - expected single argument of ALB name"
  exit 1
fi

ALB_NAME=$1

# Identify the load balancer ARN based on the name
ALB_ARN=$(aws elbv2 describe-load-balancers | jq -r '.LoadBalancers[] | select(.LoadBalancerName == "'${ALB_NAME}'") | .LoadBalancerArn')

if [ "${ALB_ARN}" = "" ]
then
  echo "No ALB found with a name of ${ALB_NAME} so exiting with error."
  exit 1
else
  echo "Found ALB with ARN: ${ALB_ARN}"
fi

# Identify the listener based on the ALB ARN and port 443
LISTENER_ARN=$(aws elbv2 describe-listeners --load-balancer-arn ${ALB_ARN} | jq -r '.Listeners[] | select(.Port == 443) | .ListenerArn')
if [ "${LISTENER_ARN}" = "" ]
then
  echo "No Listener found with a port of 443 so exiting with error."
  exit 1
else
  echo "Found listener with ARN: ${LISTENER_ARN}"
fi

# Check if there is an existing rule
RULE_ARN=$(aws elbv2 describe-rules --listener-arn ${LISTENER_ARN} | jq -r '.Rules[] | select(.Priority == "1" and .Conditions[0].Values[0] == "/chips/cff*") | .RuleArn')

if [ "${RULE_ARN}" = "" ]
then
  echo "No existing rule found with Priority 1 and Path /chips/cff* so doing nothing."
else
  echo "Existing rule found with Priority 1 and Path /chips/cff*, with ARN: ${RULE_ARN}, so removing.."
  aws elbv2 delete-rule --rule-arn ${RULE_ARN}
fi
