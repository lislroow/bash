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
          -p, --project <project name>
          -r, --run     <run type>
                        <entries>

EOF
  exit 1
}
# //usage

# options
OPTIONS="l,p:,r:"
LONGOPTIONS="project:,run:"
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
      -p | --project)
        shift; PROJECT_NAME=$1
        allows="prod local"
        if [[ ! " ${allows} " =~ " ${PROJECT_NAME} " ]]; then
          LOG "'-p, --project <project name>' requires value of [ ${allows} ]. (${PROJECT_NAME} is wrong)"
          USAGE
        fi
        ;;
      -r | --run)
        shift; RUN_TYPE=$1
        allows="build create up down stop restart"
        if [[ ! " ${allows} " =~ " ${RUN_TYPE} " ]]; then
          LOG "'-r, --run <run type>' requires value of [ ${allows} ]. (${RUN_TYPE} is wrong)"
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
  
  if [ -z "${PROJECT_NAME}" ]; then
    LOG "'-p <project name>' is required. (default: local)"
    PROJECT_NAME="local"
  fi
  if [ -z "${RUN_TYPE}" ]; then
    LOG "'-r <run type>' is required."
    USAGE
    exit 1
  fi
  DOCKER_COMPOSE_BASE=$(EXEC_R "cat $FUNCDIR/property.json | jq -r '.config .DOCKER_COMPOSE_BASE'")
  
  cat << EOF
- SetOptions
  PROJECT_NAME = $PROJECT_NAME
  DOCKER_COMPOSE_BASE = $DOCKER_COMPOSE_BASE
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
  ENTRIES=($(EXEC_R "cat $FUNCDIR/property.json | jq -r '.entries.${PROJECT_NAME}[]' | sed ''"))
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
      ENTRIES=($(EXEC_R "cat $FUNCDIR/property.json | jq -r '.entries.${PROJECT_NAME}[]' | sed ''"))
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
    
    COMPOSE_FILE="${DOCKER_COMPOSE_BASE}/${entry}.yml"
    CONTAINER_NAME="${PROJECT_NAME}.${entry}"
    IMAGE_NAME="${CONTAINER_NAME}"
    
    case ${RUN_TYPE} in
      create)
        exitCode=$(EXEC "docker-compose -p ${PROJECT_NAME} -f '${COMPOSE_FILE}' up '${CONTAINER_NAME}' --no-start")
        ;;
      up)
        exitCode=$(EXEC "docker-compose -p ${PROJECT_NAME} -f '${COMPOSE_FILE}' up '${CONTAINER_NAME}' -d")
        ;;
      down)
        exitCode=$(EXEC "docker-compose -p ${PROJECT_NAME} -f '${COMPOSE_FILE}' down '${CONTAINER_NAME}'")
        ;;
      stop)
        exitCode=$(EXEC "docker-compose -p ${PROJECT_NAME} -f '${COMPOSE_FILE}' stop '${CONTAINER_NAME}'")
        ;;
      restart)
        exitCode=$(EXEC "docker-compose -p ${PROJECT_NAME} -f '${COMPOSE_FILE}' stop '${CONTAINER_NAME}'")
        exitCode=$(EXEC "docker-compose -p ${PROJECT_NAME} -f '${COMPOSE_FILE}' up '${CONTAINER_NAME}' -d")
        ;;
    esac
    let "midx = midx + 1"
  done
}
main
# //main

exit 0