#!/bin/ksh
BASEDIR=$( cd "$( dirname "$0" )" && pwd -P )
SYSNAME=$(uname -a | awk '{ print $1 }')

# common
function USAGE {
  cat << EOF
───────────────────────────────────────────────────────────────
Usage:
-p:  p(process) 프로세스를 선택합니다.
     p 는 ps -ef | grep 에 전달됩니다.
───────────────────────────────────────────────────────────────
EOF
  exit 1
}
OPTIONS="fp:"
source ${BASEDIR}/common.inc
# -- common


# init
set -A PROC_LIST

function init {
  typeset -i proc_idx=0
  while getopts "${_OPTIONS},${OPTIONS}" opt; do
    case "$opt" in
      p)
        PROC_LIST[proc_idx]="${OPTARG}"
        proc_idx=$((proc_idx + 1))
        ;;
    esac
  done
  shift $((OPTIND - 1))
}

init "$@"
# -- init

LOG 1 "== script started"
START_TIME=$(date +%s)

set -A LOCAL_IP_LIST -- $(ifconfig -a | awk '{
  for (i=1; i<NF; i++) {
    if ($i ~ /inet/ && $(i+1) ~ /172.28/) {
      print $(i+1)
    }
  }
}')

# main
function CheckProcess {
  typeset str
  for procItem in ${PROC_LIST[@]}; do
    set -A LISTEN_LIST
    set -A OUTBOUND_LIST
    set -A INBOUND_LIST
    
    ## 프로세스 검색
    str="ps -ef | grep -v grep | grep $procItem | awk '{ print \$2 }'"
    set -A pidList -- $(eval $str)
    for pidItem in ${pidList[@]}; do
      ### pid 의 listen port 검색
      str="lsof -Pn -i4 | grep $pidItem | grep LIST | awk '{ print \$9 }' | awk -F':' '{ print \$NF }'"
      LOG 2 $str
      set -A listenList -- $(eval $str)
      for listenItem in ${listenList[@]}; do
        LOG 1 $listenItem
      done
      ### pid 의 established 검색
      str="lsof -Pn -i4 | grep $pidItem | grep ESTA | awk '{ print \$9 }'"
      set -A estaList -- $(eval $str)
      typeset -i listenCnt=${#LISTEN_LIST[*]}
      typeset -i _listenCnt=0
      while (( _listenCnt < ${#listenList[*]} )); do
        LISTEN_LIST[listenCnt]=${listenList[_listenCnt]}
        (( listenCnt += 1 ))
        (( _listenCnt += 1 ))
      done
      for estaItem in ${estaList[@]}; do
        typeset left=$(expr "${estaItem}" : '\(.*\)->')
        typeset leftIp=$(expr "${left}" : '\(.*\):.*')
        typeset leftPort=$(expr "${left}" : '.*:\(.*\)')
        typeset right=$(expr "${estaItem}" : '.*->\(.*\)')
        typeset rightIp=$(expr "${right}" : '\(.*\):.*')
        typeset rightPort=$(expr "${right}" : '.*:\(.*\)')
        #### leftIp 가 local ip 인지 확인
        typeset isLocalIp=0
        for localIpItem in ${LOCAL_IP_LIST[@]}; do
          if [ "${leftIp}" == "${localIpItem}" ]; then
            isLocalIp=1
            break;
          fi
        done
        #### leftPort 가 listen port 인지 확인
        typeset isListenPort=0
        for listenItem in ${LISTEN_LIST[@]}; do
          if [ "${listenItem}" == "${leftPort}" ]; then
            isListenPort=1
            break;
          fi
        done
        #### inbound / outbound 여부
        if [ "${isLocalIp}" -eq 1 ] && [ "${isListenPort}" -eq 1 ]; then
          INBOUND_LIST[${#INBOUND_LIST[@]}]="${estaItem}"
        else
          OUTBOUND_LIST[${#OUTBOUND_LIST[@]}]="${estaItem}"
        fi
      done
    done
    
    ## 프로세스별 socket 출력
    printf "───────────────────────────────────────────────────────────────\n"
    printf "* process: %s %s개\n" "${procItem}" "${#pidList[@]}"
    i=1
    for item in ${pidList[@]}; do
      printf "  [%s] %s\n" "$i" "${item}"
      i=$((++i))
    done
    printf "* listen port: %s개\n" "${#LISTEN_LIST[@]}"
    i=1
    for item in ${LISTEN_LIST[@]}; do
      printf "  [%s] %s\n" "$i" "${item}"
      i=$((++i))
    done
    printf "* inbound: %s개\n" "${#INBOUND_LIST[@]}"
    i=1
    for item in ${INBOUND_LIST[@]}; do
      printf "  [%s] %s\n" "$i" "${item}"
      i=$((++i))
    done
    printf "* outbound: %s개\n" "${#OUTBOUND_LIST[@]}"
    i=1
    for item in ${OUTBOUND_LIST[@]}; do
      printf "  [%s] %s\n" "$i" "${item}"
      i=$((++i))
    done
    printf "───────────────────────────────────────────────────────────────\n"
  done
}

CheckProcess

END_TIME=$(date +%s)
ELPASED_TIME=$((END_TIME - START_TIME))
LOG 1 "== script completed (elapsed time: ${ELPASED_TIME})"
