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
LONGOPTIONS="network,volume"
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
      --network)
        NETWORK_MODE=1
        ;;
      --volume)
        VOLUME_MODE=1
        ;;
      -p)
        shift
        PROJECT_NAME=$2
        ;;
      --)
        ;;
      *)
        params+=($1)
        ;;
    esac
    shift
  done
  
  if [ -z "${PROJECT_NAME}" && "${VOLUME_MODE}" == "1" ]; then
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
  
  ## network 초기화 모드
  if [ $NETWORK_MODE == 1 ]; then
    NETWORK=$(EXEC_R "cat $FUNCDIR/property.json | jq -r '.network[]' | sed ''")
    
    for network in ${NETWORK[*]}; do
      local cnt=$(EXEC_R "docker network ls --filter name=${network} -q")
      if [ $cnt -eq 1 ]; then
        LOG "'${network}' was created"
      else
        exitCode=$(EXEC "docker network create ${network}")
      fi
    done
    ## network 초기화에는 컨테이너 목록이 필요없으므로 생성 후 종료
    exit 0
  ## volume 초기화 모드
  elif [ $VOLUME_MODE == 1 ]; then
    continue
  else
    USGAE
    exit 1
  fi
  
  
  ## prepare
  ENTRIES=($(EXEC_R "cat $FUNCDIR/property.json | jq -r '.backup.entries[] | .container_name' | sed ''"))
  cat << EOF
- main
  ENTRIES = [ ${ENTRIES[*]} ]

EOF
    #exit 0
  fi
  
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
  
  ## process
  for entry in ${ENTRIES[*]}; do
    printf " \e[1;36m%s\e[0m %s\n" "[$midx/$mtot] \"$entry\""
    
    CONTAINER_NAME="${PROJECT_NAME}.${entry}"
    
    local list=($(EXEC_R "docker inspect --format '{{ json .Mounts }}' ${CONTAINER_NAME} | jq -r '.[] | \"\(.Name)|\(.Destination)\"'"))
    
    for item in ${list[*]}; do
      IFS="|" read -r VOLUME_NAME MOUNT_PATH <<< ${item}
      if [ "${VOLUME_NAME}" == "null" ]; then
        continue
      fi
      
      rslt=$(EXEC_R "docker volume ls --filter name=${VOLUME_NAME} -q")
      if [ ! -z "${rslt}" ]; then
        LOG "'${VOLUME_NAME}' was created"
        continue
      else
        exitCode=$(EXEC "docker volume create ${VOLUME_NAME}")
      fi
    done
    
    let "midx = midx + 1"
  done
}
main
# //main

exit 0