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
# -- init

LOG 1 "== script started"
START_TIME=$(date +%s)

# main
function CheckFirewall {
  typeset i=0
  IFS=''
  while read line; do
    target=$(echo $line | awk '{
      if ($1 !~ /#/) {
        printf "%s", $1
      }
    }')
    if [ -z "${target}" ]; then
      continue
    fi
    info=$(echo $line | awk '{
      for (i=1; i<=NF; i++) {
        if ($i ~ /#/) {
          for (j=i; j<=NF; j++) {
            printf "%s ", $j
          }
        }
      }
    }')
    
    IFS=':'; set -- $target; ip="$1"; port="$2"; IFS=
    
    typeset str
    str="nc -zv -w 1 -i 1 -n ${ip} ${port} 2>&1 | grep -ic 'Connected to'"
    LOG 2 $str
    CONNECTED_YN=$(eval $str)
    if [ "${CONNECTED_YN}" -gt 0 ]; then
      LOG 1 "[O] ${ip}:${port} ${info}"
    else
      LOG 0 "[X] ${ip}:${port} ${info}"
    fi
    i=$((i+1))
  done < ${BASEDIR}/check-firewall.lst
}

CheckFirewall
# -- main

END_TIME=$(date +%s)
ELPASED_TIME=$((END_TIME - START_TIME))
LOG 1 "== script completed (elapsed time: ${ELPASED_TIME})"
