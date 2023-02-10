#!/bin/bash

outfile=$1_$2_CHIPSSanityCheck.jtl

rm -f ${outfile}

~/bin/apache-jmeter-?.?/bin/jmeter.sh -n -t /apps/rundeck/scripts/service-checks/CHIPSSanityCheck.jmx -Jchips_host=$1.${RD_JOB_PROJECT,,}.heritage.aws.internal -Jchips_port=$2 -Jchips_protocol=http -Jchips_username="$3" -Jchips_password="$4" -l ${outfile} > /dev/null

cat ${outfile}

# Check for any failed responses
awk -F, '{print $8}' ${outfile} | grep false
false_check_result_code=$?

if [ ${false_check_result_code} -eq 1 ]
then
    echo "Sanity check PASSED for $1 $2"
else
    echo "Sanity check FAILED for $1 $2"
    exit 1
fi

