#!/usr/bin/env bash

BASE_DIR=$( cd "$( dirname "$0" )" && pwd -P )
#HUGO_EXEC=${BASE_DIR%/*}/hugo

if [[ "$(uname -s)" =~ MINGW|MSYS ]]; then
  HUGO_EXEC=${BASE_DIR}/hugo.exe
else
  HUGO_EXEC=${BASE_DIR}/hugo
fi

echo $HUGO_EXEC

server() {
  HUGO_OPTS="\
    --bind=0.0.0.0 \
    --port=1313 \
    --buildDrafts \
    --disableFastRender \
    --logLevel debug \
  "
  rm -rf ${BASE_DIR}/public/*
  $HUGO_EXEC server $HUGO_OPTS
}

deploy() {
  set -e
  HUGO_OPTS="\
    --cleanDestinationDir \
    --buildDrafts \
    --logLevel debug \
  "
  rm -rf ${BASE_DIR}/public/*

  $HUGO_EXEC build $HUGO_OPTS

  [[ ! -e ${BASE_DIR}/lislroow.github.io ]] && \
    mkdir -p ${BASE_DIR}/lislroow.github.io

  rm -rf ${BASE_DIR}/lislroow.github.io/*
  cp -pR public/* lislroow.github.io/
  cd ${BASE_DIR}/lislroow.github.io/
  git add .
  git commit -m 'update'
  git push
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
