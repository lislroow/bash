#!/usr/bin/env bash

BASEDIR=$(cd $(dirname $0) && pwd -P)

ssh "root@172.28.200.101" "tar cfz - $@ 2> /dev/null" \
  | tar xvfz - -C "${BASEDIR}" > /dev/null 2>&1

