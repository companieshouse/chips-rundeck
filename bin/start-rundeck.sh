#!/bin/bash

cd ${RDECK_BASE}

# Update templated config files with values from the environment
envsubst < server/config/rundeck-config.properties.template > server/config/rundeck-config.properties
envsubst < server/config/jaas-ldap.conf.template > server/config/jaas-ldap.conf
envsubst < etc/framework.properties.template > etc/framework.properties

/usr/java/jdk-8/jre/bin/java ${RUNDECK_JVM_OPTIONS} -jar /apps/rundeck/rundeck-*.war
