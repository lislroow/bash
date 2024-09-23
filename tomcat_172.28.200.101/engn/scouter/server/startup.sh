#!/bin/bash

BASE_DIR=$( cd "$( dirname "$0" )" && pwd -P )

nohup java -Xmx1024m -classpath "${BASE_DIR}/scouter-server-boot.jar" scouter.boot.Boot "${BASE_DIR}/lib" 2>&1
