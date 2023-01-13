#!/bin/bash

##############################################################################
#
# This script inserts a new listener rule into an existing CHIPS ALB that will
# redirect any requests matching the path /chips/cff* to /maintenance.
# Apache (chips-apache container) is set up to serve up a maintenance page 
# on /maintenance.
#
# The script expects a single argument that is the name of the ALB, and uses
# that name to find the ALB and then search for the listener on port 443. It
# then inserts the rule if it does not already exist.
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
  echo "No existing rule found with Priority 1 and Path /chips/cff* so proceeding to add new rule.."
  echo '
  {
	"Priority": 1,
	"Conditions": [{
		"Field": "path-pattern",
		"Values": [
			"/chips/cff*"
		]
	}],
	"Actions": [{
		"Type": "redirect",
		"Order": 1,
		"RedirectConfig": {
			"Protocol": "HTTPS",
			"Port": "#{port}",
			"Host": "#{host}",
			"Path": "/maintenance",
			"Query": "",
			"StatusCode": "HTTP_302"
		}
	}]
  }' > rule.json
  aws elbv2 create-rule --listener-arn ${LISTENER_ARN} --cli-input-json file://rule.json
else
  echo "Existing rule found with Priority 1 and Path /chips/cff*, with ARN: ${RULE_ARN}, so doing nothing."
fi
