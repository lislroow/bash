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
Usage: ${0##*/} <entries> 
          -p, --project [prod,local]: --prod, --local
          -r, --run     [build,create,up,down,stop,restart]: --build, ...

EOF
  exit 1
}
# //usage

# options
OPTIONS="l,p:,r:"
LONGOPTIONS="list,project:,run:,prod,local,build,create,up,down,stop,restart"
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
      -l | --list)
        EXEC_R "cat $FUNCDIR/property.json | jq -r '.entries.app[] | .name'"
        exit
        ;;
      -p | --project)
        shift; PROJECT_NAME=$1
        allows="prod,local"
        if [[ ! " ${allows} " =~ " ${PROJECT_NAME} " ]]; then
          LOG "'-p, --project' requires value of [ ${allows} ]. (${PROJECT_NAME} is wrong)"
          USAGE
        fi
        ;;
      --prod)
        PROJECT_NAME="prod"
        ;;
      --local)
        PROJECT_NAME="local"
        ;;
      -r | --run)
        shift; RUN_TYPE=$1
        allows="build,create,up,down,stop,restart"
        if [[ ! " ${allows} " =~ " ${RUN_TYPE} " ]]; then
          LOG "'-r, --run' requires value of [ ${allows} ]. (${RUN_TYPE} is wrong)"
          USAGE
        fi
        ;;
      --build)
        RUN_TYPE="build"
        ;;
      --create)
        RUN_TYPE="create"
        ;;
      --up)
        RUN_TYPE="up"
        ;;
      --down)
        RUN_TYPE="down"
        ;;
      --stop)
        RUN_TYPE="stop"
        ;;
      --restart)
        RUN_TYPE="restart"
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
    LOG "'-p, --project <project name>' is required."
    USAGE
  fi
  if [ -z "${RUN_TYPE}" ]; then
    LOG "'-r, --run <run type>' is required."
    USAGE
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
  ENTRIES=($(EXEC_R "cat $FUNCDIR/property.json | jq -r '.entries.app[] | .name'"))
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
    
    case "${RUN_TYPE}" in
      build)
        SOURCE=$(EXEC_R "cat $FUNCDIR/property.json | jq -r '.entries.app[] | select(.name == \"${entry}\") | .source'")
        cd ${SOURCE}
        TYPE=$(EXEC_R "cat $FUNCDIR/property.json | jq -r '.entries.app[] | select(.name == \"${entry}\") | .type'")
        case "${TYPE}" in
          java)
            exitCode=$(EXEC "./mvnw package -s ./.mvn/wrapper/settings.xml")
            ;;
        esac
        exitCode=$(EXEC "docker build -t ${entry}:latest .")
        ;;
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