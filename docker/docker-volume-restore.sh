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
  ${0##*/} -p <project name> <entries>
EOF
  exit 1
}
# //usage

# options
OPTIONS="l,p"
LONGOPTIONS=""
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
  DOCKER_COMPOSE_BASE="${DOCKER_COMPOSE_BASE}/${PROJECT_NAME}"
  
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
  
  ## process
  for entry in ${ENTRIES[*]}; do
    printf " \e[1;36m%s\e[0m %s\n" "[$midx/$mtot] \"$entry\""
    
    CONTAINER_NAME="${PROJECT_NAME}.${entry}"
    IMAGE_NAME="${CONTAINER_NAME}"
    
    # 컨테이너에 mount 된 volume 목록 조회 
    local list=$(EXEC_R "docker inspect --format '{{ json .Mounts }}' ${CONTAINER_NAME} | jq -r '.[] | \"\(.Name)|\(.Destination)\"'")
    for item in ${list[*]}; do
      # mount 명이 null 인 경우는 제외
      # mount 명이 null 로 된 것은 상대경로의 파일 디렉토리를 의미
      #   ex) docker inspect --format '{{ json .Mounts }}' 'prod.apache'' | jq -r '.[] | "\(.Name)|\(.Source)|\(.Destination)"'
      IFS="|" read -r VOLUME_NAME MOUNT_PATH <<< ${item}
      if [ "${VOLUME_NAME}" == "null" ]; then
        continue
      fi
      
      # 복원 전, 실행중인 컨테이너를 중지
      exitCode=$(EXEC "docker-compose -p ${PROJECT_NAME} -f '${DOCKER_COMPOSE_BASE}/${CONTAINER_NAME}.yml' stop '${CONTAINER_NAME}'")
      
      # 복원 전, 현재 volume 을 백업하지 않으므로 주의가 필요함
      
      # docker volume create 로 생성된 volume 에 대해서 백업을 실시
      # 백업 방식:
      #   alpine os 의 이미지로 컨테이너를 실행하면서
      #   복구 대상 volume 을 /to 로 mount 하고
      #   복구 파일(tar파일) 디렉토리(현재 디렉토리)를 /from 으로 mount 함
      #   컨테이너가 실행되면,
      #     ash 라는 shell 로 -c 다음 문자열을 실행함
      #     -c 다음 문자열은 /from 디렉토리로 이동 후 기존 파일을 삭제 후 tar 파일을 압축 해제
      exitCode=$(EXEC "docker run --rm -v ${VOLUME_NAME}:/to -v /${CURRDIR}:/from alpine ash -c 'cd /to && du -h * && rm -rf * && tar xf /from/${VOLUME_NAME}.tar'")
      
      # 백업 후, 중지된 컨테이너를 실행
      exitCode=$(EXEC "docker-compose -p ${PROJECT_NAME} -f '${DOCKER_COMPOSE_BASE}/${CONTAINER_NAME}.yml' up '${CONTAINER_NAME}' -d")
    done
    let "midx = midx + 1"
  done
}
main
# //main

exit 0