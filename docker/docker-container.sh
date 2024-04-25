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
Usage: ${0##*/} [options] <entries>

EOF
  exit 1
}
# //usage

# options
OPTIONS="l,p"
LONGOPTIONS="create,up,down"
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
      -p)
        shift 2
        PROJECT_NAME=$1
        ;;
      --create)
        CREATE_MODE=1
        ;;
      --up)
        UP_MODE=1
        ;;
      --down)
        DOWN_MODE=1
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
    LOG "'project name' is required."
    USAGE
    exit 1
  fi
  DOCKER_COMPOSE_BASE=$(EXEC_R "cat $FUNCDIR/property.json | jq -r '.config .DOCKER_COMPOSE_BASE'")
  
  cat << EOF
- SetOptions
  PROJECT_NAME = $PROJECT_NAME
  DOCKER_COMPOSE_BASE = $DOCKER_COMPOSE_BASE

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
  ENTRIES=($(EXEC_R "cat $FUNCDIR/property.json | jq -r '.backup.entries[] | .container_name' | sed ''"))
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
      ENTRIES=($(EXEC_R "cat $FUNCDIR/property.json | jq -r '.backup.entries[] | .name' | sed ''"))
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
  
  if [ "${CREATE_MODE}" == "1" ]; then
    
    ## process
    for entry in ${ENTRIES[*]}; do
      printf " \e[1;36m%s\e[0m %s\n" "[$midx/$mtot] \"$entry\""
      
      CONTAINER_NAME="${PROJECT_NAME}.${entry}"
      IMAGE_NAME="${CONTAINER_NAME}"
      
      rslt=$(EXEC_R "docker ps --filter 'Name=^${CONTAINER_NAME}$' --format '{{.Names}}'")
      if [ -z "${rslt}" ]; then
        exitCode=$(EXEC "docker-compose -p ${PROJECT_NAME} -f '${DOCKER_COMPOSE_BASE}/${CONTAINER_NAME}.yml' up '${CONTAINER_NAME}' --no-start")
      else
        LOG "'${CONTAINER_NAME}' is running"
        continue
      fi
      
      let "midx = midx + 1"
    done
    
  elif [ "${UP_MODE}" == "1" ]; then
    
    ## process
    for entry in ${ENTRIES[*]}; do
      printf " \e[1;36m%s\e[0m %s\n" "[$midx/$mtot] \"$entry\""
      
      CONTAINER_NAME="${PROJECT_NAME}.${entry}"
      IMAGE_NAME="${CONTAINER_NAME}"
      
      rslt=$(EXEC_R "docker ps --filter 'Name=^${CONTAINER_NAME}$' --format '{{.Names}}'")
      if [ -z "${rslt}" ]; then
        exitCode=$(EXEC "docker-compose -p ${PROJECT_NAME} -f '${DOCKER_COMPOSE_BASE}/${CONTAINER_NAME}.yml' up '${CONTAINER_NAME}' -d")
      else
        LOG "'${CONTAINER_NAME}' is running"
        continue
      fi
      
      let "midx = midx + 1"
    done
    
  elif [ "${DOWN_MODE}" == "1" ]; then
    
    ## process
    for entry in ${ENTRIES[*]}; do
      printf " \e[1;36m%s\e[0m %s\n" "[$midx/$mtot] \"$entry\""
      
      CONTAINER_NAME="${PROJECT_NAME}.${entry}"
      IMAGE_NAME="${CONTAINER_NAME}"
      
      rslt=$(EXEC_R "docker ps --filter 'Name=^${CONTAINER_NAME}$' --format '{{.Names}}'")
      if [ ! -z "${rslt}" ]; then
        exitCode=$(EXEC "docker-compose -p ${PROJECT_NAME} -f '${DOCKER_COMPOSE_BASE}/${CONTAINER_NAME}.yml' down '${CONTAINER_NAME}'")
      else
        LOG "'${CONTAINER_NAME}' is not running"
        continue
      fi
      
      let "midx = midx + 1"
    done
    
  fi
}
main
# //main

exit 0