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
Usage: ${0##*/} 
          --goal        <goal>
                        <entries>

EOF
  exit 1
}
# //usage

# options
OPTIONS="l"
LONGOPTIONS="goal:"
eval "source \"$BASEDIR/common.sh\""
LIST_MODE=0
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
      --goal)
        shift; GOAL=$1
        allows="clean compile package install deploy"
        if [[ ! " ${allows} " =~ " ${GOAL} " ]]; then
          LOG "'--goal <goal>' requires value of [ ${allows} ]. (${GOAL} is wrong)"
          USAGE
        fi
        ;;
      --)
        ;;
      *)
        params+=($1)
        ;;
    esac
    shift
  done
  
  if [ -z "${GOAL}" ]; then
    LOG "'--goal <goal>' is required. (default: install)"
    GOAL="install"
  fi
  
  cat << EOF
- SetOptions
  RUN_TYPE = $RUN_TYPE

EOF
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
  ENTRIES=($(EXEC_R "cat $FUNCDIR/property.json | jq -r '.entries.spring[] | .name'"))
  cat << EOF
- main
  ENTRIES = [ ${ENTRIES[*]} ]

EOF
  
  ## entries
  if [ ${#params[*]} -gt 0 ]; then
    IFS=","; read -a ENTRIES <<< ${params[*]}; unset IFS
  fi
  mtot=${#ENTRIES[*]}
  midx=1
  for entry in ${ENTRIES[*]}; do
    if [ $entry == 'all' ]; then
      ENTRIES=($(EXEC_R "cat $FUNCDIR/property.json | jq -r '.entries.spring[] | .name'"))
      mtot=${#ENTRIES[*]}
      break
    fi
  done
  
  cat << EOF
- main
  params = ${params[*]}
  ENTRIES = [ ${ENTRIES[*]} ]
  mtot = $mtot

EOF
  
  ## process
  for entry in ${ENTRIES[*]}; do
    printf " \e[1;36m%s\e[0m %s\n" "[$midx/$mtot] \"$entry\""
    
    SOURCE=$(EXEC_R "cat $FUNCDIR/property.json | jq -r '.entries.app[] | select(.name == \"${entry}\") | .source'")
    cd ${SOURCE}
    
    #exitCode=$(EXEC "./mvnw ${GOAL} -e -s ./.mvn/wrapper/settings.xml")
    #exitCode=$(EXEC "./mvnw ${GOAL} -e -s /c/develop/tools/maven/conf/settings.xml")
    exitCode=$(EXEC "./mvnw -U ${GOAL}")
    
    let "midx = midx + 1"
  done
}
main
# //main

exit 0