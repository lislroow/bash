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
Usage: $0 [options] <entries>
EOF
  exit 1
}
# //usage

# options
OPTIONS="l,a"
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
      --a | --archive)
        LIST_MODE=0
        ARCHIVE_MODE=1
        ;;
      --)
        ;;
      *)
        params+=($1)
        ;;
    esac
    shift
  done
  
  PROJECT_NAME=$(EXEC_R "cat $FUNCDIR/property.json | jq -r '.config .PROJECT_NAME'")
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
  if [ $LIST_MODE == 1 ] || [ -z "${params[*]}" ]; then
    ENTRIES=($(EXEC_R "cat $FUNCDIR/property.json | jq -r '.backup.entries[] | .container_name' | sed ''"))
    cat << EOF
- main
  ENTRIES = [ ${ENTRIES[*]} ]

EOF
  fi
  
  ## entries
  #IFS=","; read -a ENTRIES <<< ${params[*]}; unset IFS
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
    
    CONTAINER_NAME="${entry}"
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
      
      # 백업 전, 실행중인 컨테이너를 중지
      exitCode=$(EXEC "docker-compose -f '${DOCKER_COMPOSE_BASE}/${CONTAINER_NAME}.yml' stop '${CONTAINER_NAME}'")
      
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
      exitCode=$(EXEC "docker-compose -f '${DOCKER_COMPOSE_BASE}/${CONTAINER_NAME}.yml' up '${CONTAINER_NAME}' -d")
    done
    let "midx = midx + 1"
  done
}
main
# //main

exit 0