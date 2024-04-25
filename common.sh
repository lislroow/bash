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

cat << EOF
  DEBUG_MODE = $DEBUG_MODE

EOF

if [ $DEBUG_MODE == 1 ]; then
  cat << EOF
- common.sh
  ** VAR **
  CURRDIR  = $CURRDIR
  FUNCFILE = $FUNCFILE
  FUNCDIR  = $FUNCDIR
  BASEDIR  = $BASEDIR
  PROP     = \$( cat $FUNCDIR/property.json )

EOF
fi
# //[1] options


# [2] functions
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
  
  printf "%s %s \e[1;37m%s %s\e[0m %s" "$TS" "[$func:$lineNo]" "\$" "$cmd" $'\n' 1>&2
  local start=$( date +%s%N )
  # local rslt=$(bash -c "$cmd") # @see EXEC_R
  bash -c "$cmd" 1>&2
  local exitCode=$?
  local end=$( date +%s%N )
  if [ $exitCode -eq 0 ]; then
    printf "%s(\e[0;32msuccess:%d\e[0m, %'d ms)\n" $'\n' $exitCode $(($(($end - $start))/1000000)) 1>&2
  else
    printf "%s(\e[0;31merror:%d\e[0m, %'d ms)\n" $'\n' $exitCode $(($(($end - $start))/1000000)) 1>&2
  fi
  echo $exitCode
  # if [ ! -z "${rslt[*]}" ]; then   # @see EXEC_R
  #   printf "${rslt[*]}"
  # fi
}

function EXEC_R {
  local cmd=$*
  local func=${FUNCNAME[1]}
  local lineNo=${BASH_LINENO[0]}
  local TS=`date "+%Y-%m-%d %H:%M:%S"`
  
  printf "%s %s \e[1;37m%s %s\e[0m %s" "$TS" "[$func:$lineNo]" "\$" "$cmd" $'\n' 1>&2
  local start=$( date +%s%N )
  local rslt=$(bash -c "$cmd")
  local exitCode=$?
  local end=$( date +%s%N )
  if [ $exitCode -eq 0 ]; then
    printf "%s(\e[0;32msuccess:%d\e[0m, %'d ms)\n" $'\n' $exitCode $(($(($end - $start))/1000000)) 1>&2
  else
    printf "%s(\e[0;31merror:%d\e[0m, %'d ms)\n" $'\n' $exitCode $(($(($end - $start))/1000000)) 1>&2
  fi
  if [ ! -z "${rslt[*]}" ]; then
    printf "${rslt[*]}"
  fi
}

function GetProp {
  jq -r '.'$1 <<< $PROP | sed '' | {
    read value
    echo $value
  }
}
# //[2] functions

# [3] config
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
# //[3] config
