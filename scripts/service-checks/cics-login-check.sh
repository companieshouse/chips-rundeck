#!/bin/bash

outfile=$1_$2_CICSLoginCheck.jtl

rm -f ${outfile}

~/bin/apache-jmeter-?.?/bin/jmeter.sh -n -t /apps/rundeck/scripts/service-checks/CICSLoginCheck.jmx -Jcics_host=$1 -Jcics_username="$2" -Jcics_password="$3" -l ${outfile} > /dev/null

cat ${outfile}

# Check for any failed responses
awk -F, '{print $8}' ${outfile} | grep false
false_check_result_code=$?

if [ ${false_check_result_code} -eq 1 ]
then
    echo "Login check PASSED for $1" 
else
    echo "Login check FAILED for $1"
    exit 1
fi
