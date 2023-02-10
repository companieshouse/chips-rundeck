FROM 300288021642.dkr.ecr.eu-west-2.amazonaws.com/ch-serverjre:1.2.1


ENV RDECK_BASE=/apps/rundeck \
    ARTIFACTORY_BASE_URL=http://repository.aws.chdev.org:8081/artifactory

RUN mkdir -p /apps && \
    chmod a+xr /apps && \
    useradd -d ${RDECK_BASE} -m -s /bin/bash rundeck && \
    yum -y install gettext && \
    yum -y install jq && \
    yum clean all && \
    rm -rf /var/cache/yum

COPY --chown=rundeck:rundeck bin ${RDECK_BASE}/bin/

# Install AWS CLI and extract JMeter
RUN cd ${RDECK_BASE}/bin && \
    if compgen -G "awscli-exe-linux-x86_64-*.zip" > /dev/null; then \
      unzip awscli-exe-linux-x86_64-*.zip && \
      ./aws/install && \
      rm -r awscli-exe-linux-x86_64-*.zip; \
    fi; \
    if compgen -G "apache-jmeter-*.zip" > /dev/null; then \
      unzip apache-jmeter-*.zip && \
      rm -r apache-jmeter-*.zip; \
    fi;

# Install RunDeck war
USER rundeck
COPY rundeck-*.war ${RDECK_BASE}
RUN cd ${RDECK_BASE} && \
    /usr/java/jdk-8/bin/java -Xmx4g -jar rundeck-*.war --installonly

COPY --chown=rundeck:rundeck etc ${RDECK_BASE}/etc/
COPY --chown=rundeck:rundeck server ${RDECK_BASE}/server/
COPY --chown=rundeck:rundeck i18n ${RDECK_BASE}/i18n/
COPY --chown=rundeck:rundeck scripts ${RDECK_BASE}/scripts/

# Add ojdbc jar for Oracle DB and any additional plugin jars
RUN mkdir -p ${RDECK_BASE}/server/lib && \
    cd ${RDECK_BASE}/server/lib && \
    curl ${ARTIFACTORY_BASE_URL}/virtual-release/com/oracle/database/jdbc/ojdbc8/21.3.0.0/ojdbc8-21.3.0.0.jar -o ojdbc8-21.3.0.0.jar && \
    mkdir -p ${RDECK_BASE}/libext && \
    cd ${RDECK_BASE}/libext && \
    curl ${ARTIFACTORY_BASE_URL}/virtual-release/com/bitplaces/rundeck/slack-notification/1.2.4/slack-notification-1.2.4.jar -o slack-notification-1.2.4.jar


CMD ["/apps/rundeck/bin/start-rundeck.sh"]
