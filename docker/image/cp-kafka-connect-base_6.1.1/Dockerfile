FROM confluentinc/cp-kafka-connect-base:6.1.1

ENV CONNECT_PLUGIN_PATH="/usr/share/java,/usr/share/confluent-hub-components" \
    CUSTOM_SMT_PATH="/usr/share/java/custom-smt" \
    CUSTOM_CONNECTOR_MYSQL_PATH="/usr/share/java/custom-connector-mysql" \
    CUSTOM_CONNECTOR_SCYLLA_PATH="/usr/share/java/custom-connector-scylla"


ARG CONNECT_TRANSFORM_VERSION=1.4.0
ARG DEBEZIUM_VERSION=1.5.0
ARG SCYLLA_CDC_VERSION=1.0.0


# Download Using confluent-hub
RUN confluent-hub install --no-prompt confluentinc/connect-transforms:$CONNECT_TRANSFORM_VERSION


# Download Custom Source Connector
RUN mkdir $CUSTOM_CONNECTOR_MYSQL_PATH && cd $CUSTOM_CONNECTOR_MYSQL_PATH && \
    curl -sO https://repo1.maven.org/maven2/io/debezium/debezium-connector-mysql/$DEBEZIUM_VERSION.Final/debezium-connector-mysql-$DEBEZIUM_VERSION.Final-plugin.zip && \
    jar xvf debezium-connector-mysql-$DEBEZIUM_VERSION.Final-plugin.zip && \
    rm debezium-connector-mysql-$DEBEZIUM_VERSION.Final-plugin.zip

RUN mkdir $CUSTOM_CONNECTOR_SCYLLA_PATH && cd $CUSTOM_CONNECTOR_SCYLLA_PATH && \
    curl -sO https://repo1.maven.org/maven2/com/scylladb/scylla-cdc-source-connector/$SCYLLA_CDC_VERSION/scylla-cdc-source-connector-$SCYLLA_CDC_VERSION-jar-with-dependencies.jar

