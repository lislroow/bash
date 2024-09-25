#!/bin/bash

# VAR
CURRDIR=$( pwd -P )
FUNCDIR=$( cd "$( dirname "$0" )" && pwd -P )
BASEDIR=$( cd "$( dirname "$0" )" && cd .. && pwd -P )
PROP=$( bash -c "cat \"$FUNCDIR/property.json\"" )
# //VAR

# usage
function USAGE {
  cat << EOF
- USAGE
Usage: ${0##*/} <entries> 
          -p, --project [prod,local]: --prod, --local

EOF
  exit 1
}
# //usage

# options
OPTIONS="l,p:"
LONGOPTIONS="list,project:,prod,local"
eval "source \"$BASEDIR/common.sh\""
function SetOptions {
  opts=$( getopt --options "${_OPTIONS}",$OPTIONS \
                 --longoptions "${_LONGOPTIONS}",$LONGOPTIONS \
                 -- "$@" )
  eval set -- "${opts}"
  
  if [ "${DEBUG_MODE}" == 1 ]; then
    LOG "opts: " "${opts}"
  fi
  
  while true; do
    if [ -z "$1" ]; then
      break
    fi
    case $1 in
      -h | -v | --help | --verbose) ;;
      -l | --list)
        EXEC_R "cat $FUNCDIR/property.json | jq -r '.backup.volumes[]'"
        exit
        ;;
      -p | --project)
        shift; PROJECT_NAME=$1
        allows="prod,local"
        if [[ ! " ${allows} " =~ ${PROJECT_NAME} ]]; then
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
      --)
        ;;
      *)
        params+=("$1")
        ;;
    esac
    shift
  done
  
  if [ -z "${PROJECT_NAME}" ]; then
    LOG "'-p <project name>' is required."
    USAGE
  fi
  DOCKER_COMPOSE_BASE=$(EXEC_R "cat $FUNCDIR/property.json | jq -r '.config .DOCKER_COMPOSE_BASE'")
  
  cat << EOF
- SetOptions
  PROJECT_NAME = $PROJECT_NAME
  DOCKER_COMPOSE_BASE = $DOCKER_COMPOSE_BASE

EOF
}
SetOptions "$@"
if [ $? -ne 0 ]; then
  USAGE
  exit 1
fi
# //options

# main
function main {
  ## prepare
  mapfile -t ENTRIES < <(EXEC_R "cat $FUNCDIR/property.json | jq -r '.backup.volumes[]'")
  cat << EOF
- main
  ENTRIES = [ ${ENTRIES[*]} ]

EOF
  
  ## entries
  if [ ${#params[*]} -gt 0 ]; then
    IFS=","; read -r -a ENTRIES <<< "${params[@]}"; unset IFS
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
  for entry in "${ENTRIES[@]}"; do
    printf " \e[1;36m%s\e[0m %s\n" "[$midx/$mtot]" "\"$entry\""
    
    compose=$(EXEC_R "cat $FUNCDIR/property.json | jq -r '.entries[\"${PROJECT_NAME}\"] | .[] | select(.service == \"${entry}\") | \"\(.compose)\"'")
    
    COMPOSE_FILE="${DOCKER_COMPOSE_BASE}/${compose}"
    CONTAINER_NAME="${PROJECT_NAME}.${entry}"
    IMAGE_NAME="${entry}"
    
    # 컨테이너에 mount 된 volume 목록 조회 
    local list
    mapfile -t list < <(EXEC_R "docker inspect --format '{{ json .Mounts }}' ${CONTAINER_NAME} | jq -r '.[] | \"\(.Name)|\(.Destination)\"'")
    for item in "${list[@]}"; do
      # mount 명이 null 인 경우는 제외
      # mount 명이 null 로 된 것은 상대경로의 파일 디렉토리를 의미
      #   ex) docker inspect --format '{{ json .Mounts }}' 'prod.apache'' | jq -r '.[] | "\(.Name)|\(.Source)|\(.Destination)"'
      IFS="|" read -r VOLUME_NAME MOUNT_PATH <<< "${item}"
      if [ "${VOLUME_NAME}" == "null" ]; then
        continue
      fi
      
      # 백업 전, 실행중인 컨테이너를 중지
      exitCode=$(EXEC "docker-compose -p ${PROJECT_NAME} -f '${COMPOSE_FILE}' stop '${CONTAINER_NAME}'")
      
      # docker volume create 로 생성된 volume 에 대해서 백업을 실시
      # 백업 방식:
      #   alpine os 의 이미지로 컨테이너를 실행하면서
      #   백업 대상 volume 을 /from 으로 mount 하고
      #   현재 디렉토리를 /to 로 mount 함  
      #   컨테이너가 실행되면,
      #     ash 라는 shell 로 -c 다음 문자열을 실행함
      #     -c 다음 문자열은 /from 디렉토리의 모든 파일을 /to/압축파일.tar 로 생성 
      exitCode=$(EXEC "docker run --rm -v ${VOLUME_NAME}:/from -v /${CURRDIR}:/to alpine ash -c 'cd /from && tar cf /to/${VOLUME_NAME}.tar *'")
      
      # 백업 후, 중지된 컨테이너를 실행
      exitCode=$(EXEC "docker-compose -p ${PROJECT_NAME} -f '${COMPOSE_FILE}' up '${CONTAINER_NAME}' -d")
    done
    ((midx++))
  done
}
main
# //main

exit 0