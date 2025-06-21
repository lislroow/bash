#!/bin/ksh

# env
OUTLOG=/app/jeus/e1002317/cmd_$(date +%Y%m%d).log
UNIT_GB=000000000
UNIT_MB=000000
UNIT_KB=000

# common
function USAGE {
  cat << EOF
Usage:
───────────────────────────────────────────────────────────────
--clear-log   │ /logs/pgm 로그 파일을 정리합니다.
--kill-batch  │ btuser 로 실행중인 배치 프로세스를 강제 종료시킵니다.
───────────────────────────────────────────────────────────────
EOF
  exit 1
}

function LOG {
  local str="$@"
  TS=$(date +%Y-%m-%d\ %H:%M:%S)
  if [ ${DEBUG_MODE} -eq 1 ]; then
    echo "[${TS}][debug]" "${str}" | tee -a $OUTLOG
  else
    echo "[${TS}][info]" "${str}" | tee -a $OUTLOG
  fi
}

function RUN {
  local str="$@"
  LOG "${str}"
  /bin/ksh -c "${str}"
}

# //common

# execute
function execute {
  LOG "$@"
  IFS=','; set -a tasks $@; unset IFS
  local cmd
  for task in "${tasks[@]}"; do
    case $task in
    clear-log)
      cmd="find /logs/pgm -type f -size +200${UNIT_KB} -mmin +60"
      LOG=$cmd
      set -A files $(/bin/ksh -c "${cmd}")
      typeset -a entries
      for file in "${files[@]}"; do
        if [[ "$file" == *" "* ]]; then
          LOG "ERROR: filename contains spaces. $file"
          continue
        fi
        entries[${entries[@]}]=$file
        LOG $(ls -al ${file})
      done
      for file in "${entries[@]}"; do
        RUN "cat /dev/null > $file"
      done
      ;;
    kill-batch)
      cmd="ps -ef | grep -v grep | grep btuser | grep JobRunnerMain | awk '{
        for (i=1; i<=NF; i++) {
          if ($i ~ /JobRunnerMain$/) {
            print $2 " " $(i+1)
            break
          }
        }
      }
      '"
      RUN "${cmd}"
      ;;
    esac
  done
}

OPTIONS="h,d"
LONGOPTIONS="help,execute=.*"
DEBUG_MODE=0
function main {
  opts=$( getopt --options "${OPTIONS}" \
                 --longoptions "${LONGOPTIONS}" \
                 -- "$@" )
  eval set -- "${opts}"

  while true; do
    if [ -z "$1" ]; then
      break
    fi
    case $1 in
    -h)
      USAGE
      ;;
    -d)
      DEBUG_MODE=1
      ;;
    --execute=*)
      local list="${1#--execute=}"
      if [ ${#list[@]} -gt 0 ]; then
        execute "${list[@]}"
      fi
      ;;
    --status=*)
      local list="${1#--status=}"
      if [ ${#list[@]} -gt 0 ]; then
        status "${list[@]}"
      fi
      ;;
    *)
      ;;
  done
}

main "$@"
