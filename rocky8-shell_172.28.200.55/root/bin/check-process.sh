#!/bin/ksh
BASEDIR=$(cd "$(dirname "$0")" && pwd -P)
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
OPTIONS="ap:w:"
source ${BASEDIR}/common.inc
# -- common


# init
if [ $# -eq 0 ]; then
  set -- -a
fi

set -A PROC_LIST

function init {
  typeset -i proc_idx=0
  while getopts "${_OPTIONS},${OPTIONS}" opt; do
    case "$opt" in
      a)
        typeset -i i=0
        OLD_IFS=$IFS
        while IFS= read line; do
          PROC_LIST[i]=$line
          i=$((i+1))
        done < /root/bin/check-process_`hostname`.lst
        IFS=$OLD_IFS
        break
        ;;
      p)
        PROC_LIST[proc_idx]=${OPTARG}
        proc_idx=$((proc_idx+1))
        ;;
      w)
        LOG_LEVEL=2
        typeset str="grep '$OPTARG' ${BASEDIR}/check-process-knownport.lst | awk -F'|' '{ print \$1 \" # \" \$2 }'"
        RUN $str
        exit
        ;;
    esac
  done
  shift $((OPTIND-1))
}

init "$@"
# -- init

LOG 2 "== script started"
START_TIME=$(date +%s)

set -A localList -- $(ifconfig -a | awk '{
  for (i=1; i<NF; i++) {
    if ($i ~ /inet$/ && $(i+1) ~ /172.28/) {
      print $(i+1)
    }
  }
}')

# main
function CheckProcess {
  typeset str
  for procItem in ${PROC_LIST[@]}; do
    set -A listenResult
    set -A outboundResult
    set -A inboundResult
    
    ## 프로세스 검색
    typeset procNm=$(expr "${procItem}" : "\(.*\)|.*")
    typeset procGrep=$(expr "${procItem}" : ".*|\(.*\)")
    str="ps -ef | grep -v grep | grep $procGrep | awk '{ print \$2 }'"
    LOG 2 "$str"
    set -A pidList -- $(eval $str)
    for pidItem in ${pidList[@]}; do
      ### pid 의 listen port 검색
      str="lsof -Pn -i4 | grep $pidItem | grep LIST | awk '{ print \$9 }' | awk -F':' '{ print \$NF }'"
      LOG 2 "$str"
      set -A listenList -- $(eval $str)
      for listenItem in ${listenList[@]}; do
        LOG 1 "$listenItem"
      done

      ### pid 의 established 검색
      str="lsof -Pn -i4 | grep $pidItem | grep ESTA | awk '{ print \$9 }'"
      LOG 2 "$str"
      set -A estaList -- $(eval $str)
      typeset -i idx=0
      while ((idx < ${#listenList[@]})); do
        listenResult[${#listenResult[@]}+idx]=${listenList[idx]}
        idx=$((idx+1))
      done
      for estaItem in ${estaList[@]}; do
        typeset left=$(expr "${estaItem}" : '\(.*\)->')
        typeset leftIp=$(expr "${left}" : '\(.*\):.*')
        typeset leftPort=$(expr "${left}" : '.*:\(.*\)')
        typeset right=$(expr "${estaItem}" : '.*->\(.*\)')
        typeset rightIp=$(expr "${right}" : '\(.*\):.*')
        typeset rightPort=$(expr "${right}" : '.*:\(.*\)')
        
        #### leftIp 가 local 인지 확인
        typeset isLocalIp=0
        for localItem in ${localList[@]}; do
          if [ "${localItem}" == "${leftIp}" ]; then
            isLocalIp=1
            break
          fi
        done
        
        #### leftPort 가 listen port 인지 확인
        typeset isListenPort=0
        for listenItem in ${listenResult[@]}; do
          if [ "${listenItem}" == "${leftPort}" ]; then
            isListenPort=1
            break
          fi
        done
        
        #### local 연결은 제외
        if [ $isLocalIp -eq 1 ] && [ "${leftIp}" == "${rightIp}" ]; then
          continue
        fi
        
        #### inbound / outbound 여부
        if [ "${isLocalIp}" -eq 1 ] && [ "${isListenPort}" -eq 1 ]; then
          inboundResult[${#inboundResult[@]}]="${estaItem}"
        else
          outboundResult[${#outboundResult[@]}]="${estaItem}"
        fi
      done
    done
    
    ## 프로세스별 socket 출력
    printf "───────────────────────────────────────────────────────────────\n"
    printf "* process: %s %d개\n" "${procNm}" ${#pidList[@]}
    typeset -i i=1
    for item in ${pidList[@]}; do
      printf "  %2d) %s\n" $i "${item}"
      i=$((i+1))
    done
    printf "* listen port: %d개\n" ${#listenResult[@]}
    i=1
    for item in ${listenResult[@]}; do
      printf "  %2d) %s\n" $i "${item}"
      i=$((i+1))
    done
    printf "* inbound: %d개\n" ${#inboundResult[@]}
    i=1
    for item in ${inboundResult[@]}; do
      printf "  %2d) %s\n" $i "${item}"
      i=$((i+1))
    done
    printf "* outbound: %d개\n" ${#outboundResult[@]}
    i=1
    for item in ${outboundResult[@]}; do
      printf "  %2d) %s\n" $i "${item}"
      i=$((i+1))
    done
    printf "───────────────────────────────────────────────────────────────\n"
  done
}

CheckProcess

END_TIME=$(date +%s)
ELAPSED_TIME=$((END_TIME - START_TIME))
LOG 2 "== script completed (elapsed time: ${ELAPSED_TIME})"
