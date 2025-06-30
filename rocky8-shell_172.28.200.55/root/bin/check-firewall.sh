#!/bin/ksh
BASEDIR=$( cd "$( dirname "$0" )" && pwd -P )
SYSNAME=$(uname -a | awk '{ print $1 }')

# common
function USAGE {
  cat << EOF
───────────────────────────────────────────────────────────────
Usage:
───────────────────────────────────────────────────────────────
EOF
  exit 1
}
OPTIONS="fp:"
source ${BASEDIR}/common.inc
# -- common


# init
if [ "${LOG_LEVEL}" -eq 0 ]; then
  LOG_LEVEL=1
fi
# -- init

LOG 2 "== script started"
START_TIME=$(date +%s)

# main
function CheckFirewall {
  typeset -i i=0
  set -A result
  typeset -i succ=0
  typeset -i fail=0
  while IFS= read line; do
    typeset target=$(echo $line | awk '{
      if ($1 !~ /#/) {
        printf "%s", $1
      }
    }')
    if [ -z "${target}" ]; then
      continue
    fi
    typeset info=$(echo $line | awk '{
      for (i=1; i<=NF; i++) {
        if ($i ~ /#/) {
          for (j=i+1; j<=NF; j++) {
            printf "%s ", $j
          }
        }
      }
    }')
    
    IFS=':'; set -- $target; ip="$1"; port="$2"; IFS=
    
    typeset str
    str="nc -zv -w 1 -i 1 -n ${ip} ${port} 2>&1 | grep -ic 'Connected to'"
    LOG 2 $str
    typeset CONNECTED_YN=$(eval $str)
    if [ "${CONNECTED_YN}" -gt 0 ]; then
      LOG 1 "[O] ${ip}:${port} # ${info}"
      result[i]="O|${ip}:${port}|${info}"
      succ=$((succ+1))
    else
      LOG 0 "[X] ${ip}:${port} # ${info}"
      result[i]="X|${ip}:${port}|${info}"
      fail=$((fail+1))
    fi
    i=$((i+1))
  done < ${BASEDIR}/check-firewall.lst

  
  printf "───────────────────────────────────────────────────────────────\n"
  printf "* 체크결과: %d개 (실패: %d)\n" ${#result[@]} ${fail}
  typeset -i i=1
  for item in ${result[@]}; do
    ok_yn=$(echo "${item}" | cut -d'|' -f1)
    target=$(echo "${item}" | cut -d'|' -f2)
    info=$(echo "${item}" | cut -d'|' -f3)
    printf "  %s) [%s] %s # %s\n" "$i" "$ok_yn" "$target" "$info"
    i=$((i+1))
  done
  printf "───────────────────────────────────────────────────────────────\n"
}

CheckFirewall
# -- main

END_TIME=$(date +%s)
ELAPSED_TIME=$((END_TIME - START_TIME))
LOG 2 "== script completed (elapsed time: ${ELAPSED_TIME})"
