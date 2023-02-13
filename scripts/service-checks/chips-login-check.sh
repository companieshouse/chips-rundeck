#!/bin/bash
echo "Starting CHIPSLoginCheck"

logfile=/tmp/$1_$2_CHIPSLoginCheck.log
outfile=/tmp/$1_$2_CHIPSLoginCheck.jtl

rm -f ${outfile}

~/bin/apache-jmeter-?.?/bin/jmeter.sh -n -t /apps/rundeck/scripts/service-checks/CHIPSLoginCheck.jmx -Jchips_host=$1 -Jchips_port=443 -Jchips_protocol=https -Jchips_username="$2" -Jchips_password="$3" -j ${logfile} -l ${outfile} > /dev/null

cat ${outfile}

# Check for any failed responses
grep ",false," ${outfile}
false_check_result_code=$?

if [ ${false_check_result_code} -eq 1 ]
then
    echo "Login check PASSED for $1" 
else
    echo "Login check FAILED for $1"
    exit 1
fi

