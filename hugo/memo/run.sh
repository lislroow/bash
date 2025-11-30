#!/usr/bin/env bash

BASE_DIR=$( cd "$( dirname "$0" )" && pwd -P )
HUGO=${BASE_DIR%/*}/bin/hugo

HUGO_VERSION=$( $HUGO version )
echo -e "\e[0;32m${HUGO_VERSION}\e[0m"

server() {
  HUGO_OPTS=""
  HUGO_OPTS="${HUGO_OPTS} --bind=0.0.0.0"
  HUGO_OPTS="${HUGO_OPTS} --port=1313"
  HUGO_OPTS="${HUGO_OPTS} --buildDrafts"
  HUGO_OPTS="${HUGO_OPTS} --disableFastRender"
  HUGO_OPTS="${HUGO_OPTS} --logLevel debug"
  
  HUGO_CMD="${HUGO} server ${HUGO_OPTS}"
  echo "${HUGO_CMD}"
  eval "${HUGO_CMD}"
}

deploy() {
  HUGO_OPTS=""
  HUGO_OPTS="${HUGO_OPTS} --cleanDestinationDir"
  
  HUGO_CMD="${HUGO} ${HUGO_OPTS}"
  echo "${HUGO_CMD}"
  eval "${HUGO_CMD}"
  
  CMD="rm -rf lislroow.github.io/*"
  echo "${CMD}"
  eval "${CMD}"
  
  CMD="cp -R public/* lislroow.github.io/"
  echo "${CMD}"
  eval "${CMD}"
  
  CMD="cd lislroow.github.io/ && git add . && git commit -m 'update' && git push"
  echo "${CMD}"
  eval "${CMD}"
}


case $1 in
  server)
    server
    ;;
  deploy)
    deploy
    ;;
  *)
    server
    ;;
esac
