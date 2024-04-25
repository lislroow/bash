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
 -l            : <entries> 보기
 -a            : docker container 백업하기

EOF
  exit 1
}
# //usage

# options
OPTIONS="l,p"
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
      -p)
        shift 2
        PROJECT_NAME=$1
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
  ENTRIES=($(EXEC_R "cat $FUNCDIR/property.json | jq -r '.backup.entries[] | .container_name' | sed ''"))
  cat << EOF
- main
  ENTRIES = [ ${ENTRIES[*]} ]

EOF
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
    IMAGE_NAME="${CONTAINER_NAME}"
    
    rslt=$(EXEC_R "docker ps --filter 'Name=^${CONTAINER_NAME}$' --format '{{.Names}}'")
    if [ -z "${rslt}" ]; then
      LOG "'${CONTAINER_NAME}' not running. attempting to start ..."
      exitCode=$(EXEC "docker-compose -f '${DOCKER_COMPOSE_BASE}/${CONTAINER_NAME}.yml' up '${CONTAINER_NAME}' -d")
      if [ ${exitCode} -ne 0 ]; then
        LOG "fail to start '${CONTAINER_NAME}'"
        exit
      fi
    fi
    
    local CURR_TIME=`date +%Y%m%d_%H%M%S`
    # 실행중인 컨테이너ID 확인
    CID=$(EXEC_R "docker ps --filter 'Name=^${CONTAINER_NAME}$' --format '{{.ID}}'")
    # 실행중인 컨테이너의 이미지에서 commit
    exitCode=$(EXEC "docker commit -a 'hi@mgkim.net' -m 'backup:${IMAGE_NAME}:${CURR_TIME}' '${CID}' '${IMAGE_NAME}:${CURR_TIME}'")
    # 실행중인 컨테이너 중지 및 제거
    exitCode=$(EXEC "docker-compose -f '${DOCKER_COMPOSE_BASE}/${CONTAINER_NAME}.yml' down '${CONTAINER_NAME}'")
    # latest 태그의 이미지 삭제 (컨테이너는 항상 latest 태그 이미지로 실행함)
    exitCode=$(EXEC "docker rmi docker.io/lislroow/${IMAGE_NAME}:latest")
    # commit 으로 생성된 이미지를 latest 태그의 이미지로 만듬
    exitCode=$(EXEC "docker tag '${IMAGE_NAME}:${CURR_TIME}' 'lislroow/${IMAGE_NAME}:latest'")
    # latest 태그 이미지를 docker hub 에 push
    exitCode=$(EXEC "docker image push 'lislroow/${IMAGE_NAME}:latest'")
    
    # 오래된 백업 이미지 대상 +3 조회
    # rslt=($(EXEC_R docker image ls ${CONTAINER_NAME} -q | tail -n +3))
    # ID로 삭제할 수 없음(https://stackoverflow.com/questions/38118791/can-t-delete-docker-image-with-dependent-child-images)
    # 태그로 지워야함
    # Error response from daemon: conflict: unable to delete 2e3651b1bda7 (cannot be forced) - image has dependent child images
    rslt=($(EXEC_R "docker image ls '${CONTAINER_NAME}' --format '{{.Repository}}:{{.Tag}}' | tail -n +3"))
    if [ -n "${rslt[*]}" ]; then
      # 있으면 삭제
      exitCode=$(EXEC "docker rmi -f ${rslt[*]}")
    fi
    exitCode=$(EXEC "docker image prune -f")
    
    # latest 태그 이미지로 컨테이너 실행
    exitCode=$(EXEC "docker-compose -f '${DOCKER_COMPOSE_BASE}/${CONTAINER_NAME}.yml' up '${CONTAINER_NAME}' -d")
    
    let "midx = midx + 1"
  done
}
main
# //main

exit 0