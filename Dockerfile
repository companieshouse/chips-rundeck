FROM 300288021642.dkr.ecr.eu-west-2.amazonaws.com/chips-openjdk:1.0.0 AS builder

ARG ARTIFACTORY_URL
ARG ARTIFACTORY_USERNAME
ARG ARTIFACTORY_PASSWORD

ENV RDECK_BASE=/apps/rundeck \
    ARTIFACTORY_BASE_URL=${ARTIFACTORY_URL}/virtual-release

# Add ojdbc jar for Oracle DB and any additional plugin jars
RUN mkdir -p ${RDECK_BASE}/server/lib && \
    cd ${RDECK_BASE}/server/lib && \
    curl -L -u "${ARTIFACTORY_USERNAME}:${ARTIFACTORY_PASSWORD}" ${ARTIFACTORY_BASE_URL}/com/oracle/database/jdbc/ojdbc8/21.3.0.0/ojdbc8-21.3.0.0.jar -o ojdbc8-21.3.0.0.jar && \
    mkdir -p ${RDECK_BASE}/libext && \
    cd ${RDECK_BASE}/libext && \
    curl -L -u "${ARTIFACTORY_USERNAME}:${ARTIFACTORY_PASSWORD}" ${ARTIFACTORY_BASE_URL}/com/bitplaces/rundeck/slack-notification/1.2.4/slack-notification-1.2.4.jar -o slack-notification-1.2.4.jar && \
    curl -L -u "${ARTIFACTORY_USERNAME}:${ARTIFACTORY_PASSWORD}" ${ARTIFACTORY_BASE_URL}/uk/gov/companieshouse/rundeck-sns-notification-plugin/1.0.1/rundeck-sns-notification-plugin-1.0.1.jar -o rundeck-sns-notification-plugin-1.0.1.jar 


FROM 300288021642.dkr.ecr.eu-west-2.amazonaws.com/chips-openjdk:1.0.0

ENV RDECK_BASE=/apps/rundeck

# Set up RunDeck base directory, create rundeck user, and install required packages
# Swaps OpenJDK 21 with 11 for compatibility with current RunDeck version
RUN mkdir -p /apps && \
    chmod a+xr /apps && \
    useradd -d ${RDECK_BASE} -m -s /bin/bash rundeck && \
    yum -y update-minimal --security && \
    yum remove -y java-21-openjdk-devel.x86_64 && \
    yum install -y java-11-openjdk-devel.x86_64 && \
    yum -y install gettext && \
    yum -y install jq && \
    yum clean all && \
    rm -rf /var/cache/yum

# Copy across artifactory held jar files from the builder stage
COPY --from=builder --chown=rundeck:rundeck ${RDECK_BASE} ${RDECK_BASE}

# Install AWS CLI and extract JMeter
COPY --chown=rundeck:rundeck bin ${RDECK_BASE}/bin/
RUN cd ${RDECK_BASE}/bin && \
    if compgen -G "awscli-exe-linux-x86_64-*.zip" > /dev/null; then \
      unzip awscli-exe-linux-x86_64-*.zip && \
      ./aws/install && \
      rm -r aws awscli-exe-linux-x86_64-*.zip; \
    fi; \
    if compgen -G "apache-jmeter-*.zip" > /dev/null; then \
      unzip apache-jmeter-*.zip && \
      rm -r apache-jmeter-*.zip; \
    fi;

# Install RunDeck war
USER rundeck
COPY rundeck-*.war ${RDECK_BASE}
RUN cd ${RDECK_BASE} && \
    ${JAVA_HOME}/bin/java -Xmx4g -jar rundeck-*.war --installonly

# Override default configuration with custom etc, server, i18n, and scripts directories
COPY --chown=rundeck:rundeck etc ${RDECK_BASE}/etc/
COPY --chown=rundeck:rundeck server ${RDECK_BASE}/server/
COPY --chown=rundeck:rundeck i18n ${RDECK_BASE}/i18n/
COPY --chown=rundeck:rundeck scripts ${RDECK_BASE}/scripts/

CMD ["/apps/rundeck/bin/start-rundeck.sh"]
