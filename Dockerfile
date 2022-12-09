FROM 300288021642.dkr.ecr.eu-west-2.amazonaws.com/ch-serverjre:1.2.1


ENV RDECK_BASE=/apps/rundeck \
    ARTIFACTORY_BASE_URL=http://repository.aws.chdev.org:8081/artifactory

RUN mkdir -p /apps && \
    chmod a+xr /apps && \
    useradd -d ${RDECK_BASE} -m -s /bin/bash rundeck && \
    yum -y install gettext && \
    yum clean all && \
    rm -rf /var/cache/yum

USER rundeck

COPY rundeck-*.war ${RDECK_BASE}

RUN cd ${RDECK_BASE} && \
    /usr/java/jdk-8/bin/java -Xmx4g -jar rundeck-*.war --installonly

COPY --chown=rundeck:rundeck etc ${RDECK_BASE}/etc/
COPY --chown=rundeck:rundeck bin ${RDECK_BASE}/bin/
COPY --chown=rundeck:rundeck server ${RDECK_BASE}/server/

# Add ojdbc jar for Oracle DB
RUN mkdir -p ${RDECK_BASE}/server/lib && \
    cd ${RDECK_BASE}/server/lib && \
    curl ${ARTIFACTORY_BASE_URL}/virtual-release/com/oracle/database/jdbc/ojdbc8/21.3.0.0/ojdbc8-21.3.0.0.jar -o ojdbc8-21.3.0.0.jar


CMD ["/apps/rundeck/bin/start-rundeck.sh"]
