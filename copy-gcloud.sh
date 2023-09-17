#!/bin/bash

# VAR
CURRDIR=$( pwd -P )
FUNCFILE=$0
FUNCDIR=${FUNCFILE%/*}
BASEDIR=${FUNCDIR}
# //VAR

# usage
function USAGE {
  cat << EOF
- USAGE
Usage: $0 [options] <entries>
 -l            : <entries> 보기

EOF
  exit 1
}
# //usage

# options
OPTIONS="l"
LONGOPTIONS=""
eval "source \"$BASEDIR/common.sh\""

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
      --)
        ;;
      *)
        params+=($1)
        ;;
    esac
    shift
  done
  
  if [ -z $GCLOUD_DIR ]; then
    GCLOUD_DIR='/z/내 드라이브/bash'
  fi
  
  if [ $DEBUG_MODE == 1 ]; then
    cat << EOF
- SetOptions
  GCLOUD_DIR = $GCLOUD_DIR

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
  cd $BASEDIR ; tar cf - * .project .settings .gitignore | tar xvf - -C "$GCLOUD_DIR"
}
main
# //main

exit 0