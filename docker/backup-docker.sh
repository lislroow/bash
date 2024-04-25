#!/bin/bash

# VAR
CURRDIR=$( pwd -P )
FUNCDIR=$( cd $( dirname $0 ) && pwd -P )
BASEDIR=$( cd $( dirname $0 ) && cd .. && pwd -P )
PROP=$( bash -c "cat \"$FUNCDIR/property.json\"" )
# //VAR

# usage
function USAGE {
  cat << EOF
- USAGE
Usage: $0 [options] <entries>
 -l            : <entries> 보기
 -a            : docker container 백업하기

EOF
  exit 1
}
# //usage

# options
OPTIONS="l,a"
LONGOPTIONS=""
eval "source \"$BASEDIR/common.sh\""
LIST_MODE=0
ARCHIVE_MODE=0
function SetOptions {
  opts=$( getopt --options $_OPTIONS,$OPTIONS \
                 --longoptions $_LONGOPTIONS,$LONGOPTIONS \
                 -- $* )
  eval set -- $opts
  
  if [ $DEBUG_MODE == 1 ]; then
    LOG "opts: " $opts
  fi
  
  while true; do
    if [ -z $1 ]; then
      break
    fi
    case $1 in
      -h | -v | --help | --verbose) ;;
      -l)
        LIST_MODE=1
        ;;
      --a | --archive)
        ARCHIVE_MODE=1
        ;;
      --)
        ;;
      *)
        params+=($1)
        ;;
    esac
    shift
  done
  
  if [ -z $OUTDIR ]; then
    OUTDIR=$( GetProp "backup.outdir" )
  fi
  
  if [ $DEBUG_MODE == 1 ]; then
    cat << EOF
- SetOptions
  OUTDIR = $OUTDIR
  DRIVE = $DRIVE

EOF
  fi
}
SetOptions $*
if [ $? -ne 0 ]; then
  USAGE
  exit 1
fi
# //options

# main
function main {
  ## prepare
  if [ $LIST_MODE == 1 ] || [ -z "${params[*]}" ]; then
    ENTRIES=($( jq -r '.backup.entries[] | .name' <<< $PROP | sed '' ))
    cat << EOF
- main
  ENTRIES = [ ${ENTRIES[*]} ]

EOF
    exit 0
  fi
  
  ## process
  for entry in ${ENTRIES[*]}; do
    EXEC "docker ps | grep prod.apache | awk '{print $1}'"
    let "midx = midx + 1"
  done
}
main
# //main

exit 0