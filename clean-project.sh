#!/bin/bash
BASEDIR=$( cd "$( dirname . )" && pwd -P )

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

EOF

for item in "${LIST[@]}"; do
  if [ -z "${item}" ]; then
    continue
  fi
  rm -rf "${BASEDIR:?}/${item:?}"
done
