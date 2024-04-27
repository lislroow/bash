#!/bin/sh

LOG_BASE="/app"
SCOUTER_AGENT_DIR=/app/scouter.agent

JAVA_OPTS="-server"
JAVA_OPTS="${JAVA_OPTS} -Xms512m -Xmx512m"
#JAVA_OPTS="${JAVA_OPTS} -verbose:gc"
#JAVA_OPTS="${JAVA_OPTS} -Xloggc:${LOG_BASE}/`date +%Y%m%d_%H%M%S`-gc.log"
#JAVA_OPTS="${JAVA_OPTS} -XX:+PrintGCDetails"
#JAVA_OPTS="${JAVA_OPTS} -XX:+PrintGCDateStamps"
#JAVA_OPTS="${JAVA_OPTS} -XX:+PrintHeapAtGC"
#JAVA_OPTS="${JAVA_OPTS} -XX:+UseGCLogFileRotation"
#JAVA_OPTS="${JAVA_OPTS} -XX:+ExitOnOutOfMemoryError"
#JAVA_OPTS="${JAVA_OPTS} -XX:+HeapDumpOnOutOfMemoryError"
#JAVA_OPTS="${JAVA_OPTS} -XX:HeapDumpPath=${LOG_BASE}/dump_${APP}_`date+%Y%m%d_%H%M%S`.hprof"
#JAVA_OPTS="${JAVA_OPTS} -XX:+DisableExplicitGC"
JAVA_OPTS="${JAVA_OPTS} -Dspring.profiles.active=${SPRING_PROFILE}"
JAVA_OPTS="${JAVA_OPTS} -Dfile.encoding=utf-8"
JAVA_OPTS="${JAVA_OPTS} -Djava.net.preferIPv4Stack=true"
JAVA_OPTS="${JAVA_OPTS} -javaagent:${SCOUTER_AGENT_DIR}/scouter.agent.jar"
JAVA_OPTS="${JAVA_OPTS} -Dscuter.config=${SCOUTER_AGENT_DIR}/${SPRING_PROFILE}.scouter.conf"
JAVA_OPTS="${JAVA_OPTS} -Dobj_name=${APP_NAME}"

java ${JAVA_OPTS} -jar /app/${APP_NAME}.jar