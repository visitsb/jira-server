# Dockerfile adapted from original jira-server. Most of the portions are
# kept as-is, with some reorganization done to reduce number of instructions
# https://bitbucket.org/dchevell/docker-atlassian-jira-software/src
FROM adoptopenjdk:8-hotspot
MAINTAINER Shanti Naik <visitsb@gmail.com>

ENV RUN_USER daemon
ENV RUN_GROUP daemon

# https://confluence.atlassian.com/doc/confluence-home-and-other-important-directories-590259707.html
ENV JIRA_HOME /var/atlassian/application-data/jira
ENV JIRA_INSTALL_DIR /opt/atlassian/jira

VOLUME ["${JIRA_HOME}"]
WORKDIR $JIRA_HOME

ARG TINI_VERSION=v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /usr/local/bin/tini

COPY entrypoint.sh /usr/local/bin/

# Using MySQL JDBC drivers
ARG MYSQL_CONNECTOR_VERSION=5.1.49
ADD https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.tar.gz .

# My purchased license expired 22 Apr 2016, below is the version upto which I can go latest
# https://confluence.atlassian.com/jira/jira-6-4-13-release-notes-813700147.html
# 6.4.13 - 03 March 2016 (*)
# 6.4.14 - 28 July 2016 (x)
ARG JIRA_VERSION=6.4.13
ADD https://www.atlassian.com/software/jira/downloads/binary/atlassian-jira-${JIRA_VERSION}.tar.gz .

RUN /usr/bin/apt-get update \
 && /usr/bin/apt-get install -y --no-install-recommends fontconfig uuid-runtime \
 && /usr/bin/apt-get clean autoclean && /usr/bin/apt-get autoremove -y && /bin/rm -rf /var/lib/apt/lists/* \
 && /bin/chmod +x /usr/local/bin/tini /usr/local/bin/entrypoint.sh \
 && /bin/mkdir -p ${JIRA_INSTALL_DIR} \
 && /bin/tar -xzvf ./atlassian-jira-${JIRA_VERSION}.tar.gz --strip-components=1 -C "${JIRA_INSTALL_DIR}" \
 && /bin/tar -xzvf ./mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.tar.gz --strip-components=1 -C ${JIRA_INSTALL_DIR}/lib mysql-connector-java-${MYSQL_CONNECTOR_VERSION}/mysql-connector-java-${MYSQL_CONNECTOR_VERSION}-bin.jar \
 && /bin/chown -R ${RUN_USER}:${RUN_GROUP} ${JIRA_INSTALL_DIR}/ \
 && /bin/sed -i -e 's/^JVM_SUPPORT_RECOMMENDED_ARGS=""$/: \${JVM_SUPPORT_RECOMMENDED_ARGS:=""}/g' ${JIRA_INSTALL_DIR}/bin/setenv.sh \
 && /bin/sed -i -e 's/^JVM_\(.*\)_MEMORY="\(.*\)"$/: \${JVM_\1_MEMORY:=\2}/g' ${JIRA_INSTALL_DIR}/bin/setenv.sh \
 && /bin/sed -i -e 's/port="8080"/port="8080" secure="${catalinaConnectorSecure}" scheme="${catalinaConnectorScheme}" proxyName="${catalinaConnectorProxyName}" proxyPort="${catalinaConnectorProxyPort}"/' ${JIRA_INSTALL_DIR}/conf/server.xml \
 && /bin/sed -i -e 's/Context path=""/Context path="${catalinaContextPath}"/' ${JIRA_INSTALL_DIR}/conf/server.xml \
 && /usr/bin/touch /etc/container_id && chmod a+rw /etc/container_id

# Expose HTTP port
EXPOSE 8080

CMD ["entrypoint.sh", "-fg"]
ENTRYPOINT ["tini", "--"]
