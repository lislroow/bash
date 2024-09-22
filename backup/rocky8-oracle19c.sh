#!/bin/bash

# usage
function USAGE {
  cat << EOF
- USAGE
Usage: ${0##*/} [options]
 expdp : "oracle19c data export"
EOF
  exit 1
}
# //usage

# main
function main {
    case $1 in
      expdp)
        CURR_TIME=$(date +%Y%m%d_%H%M%S)
        DUMPFILE=$(printf "develop_%s.dmp" "${CURR_TIME}")
        ssh oracle@mgkim.net -p 51022 \
          "expdp mkuser/1@develop DIRECTORY=backup_dir DUMPFILE=${DUMPFILE} LOGFILE=${DUMPFILE}.log"
        ;;
      *)
        USAGE
        ;;
    esac
}
main "$@"
# //main
