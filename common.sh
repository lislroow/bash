#!/bin/bash

# [1] options
_OPTIONS="h,v"
_LONGOPTIONS="help,verbose"
DEBUG_MODE=0
function _SetOptions {
  opts=$( getopt --options $_OPTIONS,$OPTIONS \
                 --longoptions $_LONGOPTIONS,$LONGOPTIONS \
                 -- $* )
  eval set -- $opts
  ARGS=()
  while true; do
    if [ -z $1 ]; then
      break
    fi
    case $1 in
      -h | --help)
        USAGE
        ;;
      -v | --verbose)
        DEBUG_MODE=1
        ;;
    esac
    shift
  done
}
_SetOptions $*
if [ $? -ne 0 ]; then
  USAGE
  exit 1
fi
# //[1] options


# [2] variables
CURDIR=$( pwd -P )
CURDIRNM=${CURDIR##*/}
SCRDIR=$( cd $( dirname $0 ) && pwd -P )
BASEDIR=$( cd $( dirname $SCRDIR ) && pwd -P )
PROP=$( cat $SCRDIR/property.json )

cat << EOF
  DEBUG_MODE = $DEBUG_MODE

EOF

if [ $DEBUG_MODE == 1 ]; then
  cat << EOF
- common.sh
  ** VAR **
  CURDIR = $CURDIR
  CURDIRNM = $CURDIRNM
  SCRDIR = $SCRDIR
  BASEDIR = $BASEDIR
  PROP = \$( cat $SCRDIR/property.json )

EOF
fi
# //[2] variables


# [3] functions
function LOG {
  local str=$*
  local func lineNo
  if [ ${FUNCNAME[1]} == "EXEC" ]; then
    func=${FUNCNAME[2]}
    lineNo=${BASH_LINENO[1]}
  else
    func=${FUNCNAME[1]}
    lineNo=${BASH_LINENO[0]}
  fi
  local TS=`date "+%Y-%m-%d %H:%M:%S"`
  echo -e "$TS" "[$func:$lineNo]" $str 1>&2
}

function EXEC {
  local cmd=$*
  local func=${FUNCNAME[1]}
  local lineNo=${BASH_LINENO[0]}
  local TS=`date "+%Y-%m-%d %H:%M:%S"`
  
  printf "%s %s \e[1;37m%s \e[1;36m%s\e[0m " "$TS" "[$func:$lineNo]" "\$" "$cmd" 1>&2
  local start=$( date +%s%N )
  if [ $DEBUG_MODE == 1 ]; then
    bash -c "$cmd"
  else
    bash -c "$cmd" > /dev/null 2>&1
  fi
  local exitCode=$?
  local end=$( date +%s%N )
  if [ $exitCode -eq 0 ]; then
    printf "(\e[0;32msuccess:%d\e[0m, %'d ms)\n" $exitCode $(($(($end - $start))/1000000))
  else
    printf "(\e[0;31merror:%d\e[0m, %'d ms)\n" $exitCode $(($(($end - $start))/1000000))
  fi
}

function GetProp {
  jq -r '.'$1 <<< $PROP | sed '' | {
    read value
    echo $value
  }
}
# //[3] functions


# [4] config
function _SetConfig {
  jq -r '.config.precmd[]' <<< $PROP | {
    while read -r line; do
      eval "$line"
    done
  }
  
  list=($( jq -r '.config.env[] | "\(.name)=\(.value)"' <<< $PROP | sed '' ))
  for item in ${list[*]}; do
    eval "$item"
  done
  
  list=($( jq -r '.config.path[]' <<< $PROP | sed '' ))
  for item in ${list[*]}; do
    export PATH="$item:$PATH"
  done
  
  if [ $DEBUG_MODE == 1 ]; then
    cat << EOF
- SetConfig
  ** PATH **
  java = $(which java 2> /dev/null)
  mvn = $(which mvn 2> /dev/null)
  7z = $(which 7z 2> /dev/null)
  bcomp = $(which bcomp 2> /dev/null)
  ** ENV **
  JAVA_HOME = $(echo $JAVA_HOME)

EOF
  fi
}
_SetConfig
# //[4] config
