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
          --from   [prod,local]: --from-prod, --from-local
          --to     [prod,local]: --to-prod, --to-local

EOF
  exit 1
}
# //usage

# options
OPTIONS="l:"
LONGOPTIONS="list,from:,from-prod,from-local,to:,to-prod,to-local"
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
      --from)
        shift; FROM_PROJECT=$1
        allows="prod,local"
        if [[ ! " ${allows} " =~ ${FROM_PROJECT} ]]; then
          LOG "'--from' requires value of [ ${allows} ]. (${FROM_PROJECT} is wrong)"
          USAGE
        fi
        ;;
      --from-prod)
        FROM_PROJECT="prod"
        ;;
      --from-local)
        FROM_PROJECT="local"
        ;;
      --to)
        shift; TO_PROJECT=$1
        allows="prod,local"
        if [[ ! " ${allows} " =~ ${TO_PROJECT} ]]; then
          LOG "'--to' requires value of [ ${allows} ]. (${TO_PROJECT} is wrong)"
          USAGE
        fi
        ;;
      --to-prod)
        TO_PROJECT="prod"
        ;;
      --to-local)
        TO_PROJECT="local"
        ;;
      --)
        ;;
      *)
        params+=("$1")
        ;;
    esac
    shift
  done
  
  if [ -z "${FROM_PROJECT}" ]; then
    LOG "'--from <from project>' is required."
    USAGE
  fi
  if [ -z "${TO_PROJECT}" ]; then
    LOG "'--to <to project>' is required."
    USAGE
  fi
  
  DOCKER_COMPOSE_BASE=$(EXEC_R "cat $FUNCDIR/property.json | jq -r '.config .DOCKER_COMPOSE_BASE'")
  
  cat << EOF
- SetOptions
  FROM_PROJECT = $FROM_PROJECT
  TO_PROJECT = $TO_PROJECT
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
    CONTAINER_NAME="${TO_PROJECT}.${entry}"
    IMAGE_NAME="${entry}"
    
    # 컨테이너에 mount 된 volume 목록 조회 
    local list
    mapfile -t list < <(EXEC_R "docker inspect --format '{{ json .Mounts }}' ${CONTAINER_NAME} | jq -r '.[] | \"\(.Name)|\(.Destination)\"'")
    
    # 컨테이너가 생성되지 않았을 때 --no-start 로 생성만 실행
    if [ -z "${list[*]}" ]; then
      exitCode=$(EXEC "docker-compose -p ${TO_PROJECT} -f '${COMPOSE_FILE}' up '${CONTAINER_NAME}' --no-start")
      # 생성 실패 시 continue
      LOG "exitCode=${exitCode}"
      if [ "${exitCode}" -ne 0 ]; then
        continue
      else
        list=$(EXEC_R "docker inspect --format '{{ json .Mounts }}' ${CONTAINER_NAME} | jq -r '.[] | \"\(.Name)|\(.Destination)\"'")
      fi
    fi
    
    for item in "${list[@]}"; do
      # mount 명이 null 인 경우는 제외
      # mount 명이 null 로 된 것은 상대경로의 파일 디렉토리를 의미
      #   ex) docker inspect --format '{{ json .Mounts }}' 'prod.apache'' | jq -r '.[] | "\(.Name)|\(.Source)|\(.Destination)"'
      IFS="|" read -r VOLUME_NAME MOUNT_PATH <<< "${item}"
      if [ "${VOLUME_NAME}" == "null" ]; then
        exitCode=$(EXEC "docker-compose -p ${TO_PROJECT} -f '${COMPOSE_FILE}' up '${CONTAINER_NAME}' -d")
        continue
      fi
      TO_VOLUME=${VOLUME_NAME}
      # prod 에서 local 로 옮길때처럼 from / to 가 다른 경우,
      # "prod_mariadb_data.tar" 파일을 "local_mariadb_data" volume 에 restore 할 때 아래 문자열 치환이 필요함
      FROM_FILE=${VOLUME_NAME/${TO_PROJECT}/${FROM_PROJECT}}.tar
      
      # 복원 전, 실행중인 컨테이너를 중지
      exitCode=$(EXEC "docker-compose -p ${TO_PROJECT} -f '${COMPOSE_FILE}' stop '${CONTAINER_NAME}'")
      
      # 복원 전, 현재 volume 을 백업하지 않으므로 주의가 필요함
      
      # docker volume create 로 생성된 volume 에 대해서 백업을 실시
      # 백업 방식:
      #   alpine os 의 이미지로 컨테이너를 실행하면서
      #   복구 대상 volume 을 /to 로 mount 하고
      #   복구 파일(tar파일) 디렉토리(현재 디렉토리)를 /from 으로 mount 함
      #   컨테이너가 실행되면,
      #     ash 라는 shell 로 -c 다음 문자열을 실행함
      #     -c 다음 문자열은 /from 디렉토리로 이동 후 기존 파일을 삭제 후 tar 파일을 압축 해제
      exitCode=$(EXEC "docker run --rm -v ${VOLUME_NAME}:/to -v /${CURRDIR}:/from alpine ash -c 'cd /to && du -h && rm -rf * && tar xf /from/${FROM_FILE} && du -h'")
      
      # 백업 후, 중지된 컨테이너를 실행
      exitCode=$(EXEC "docker-compose -p ${TO_PROJECT} -f '${COMPOSE_FILE}' up '${CONTAINER_NAME}' -d")
    done

    ((midx++))
  done
}
main
# //main

exit 0