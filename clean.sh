#!/bin/bash
if [ -z "$1" ]; then
  BASEDIR=$( cd "$( dirname . )" && pwd -P )
else
  BASEDIR="$1"
fi

if [ "${BASEDIR}" == '/usr/bin' ]; then
  echo "error. BASEDIR is /usr/bin"
  exit 1
fi

mapfile -t LIST <<- EOF
.project
.settings
.classpath
.factorypath
.externalToolBuilders
.apt_generated_tests
.apt_generated
target
.gradle
build
bin
.scannerwork
.sonarlint
heapdump
logs

EOF

for item in "${LIST[@]}"; do
  if [ -z "${item}" ]; then
    continue
  fi
  rm -rf "${BASEDIR:?}/${item:?}"
  rm -rf "${BASEDIR:?}"/*/"${item:?}"
done
