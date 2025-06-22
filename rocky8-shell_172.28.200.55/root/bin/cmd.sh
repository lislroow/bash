#!/bin/ksh

# env
OUTLOG=/app/jeus/e1002317/cmd_$(date +%Y%m%d).log
UNIT_GB=000000000
UNIT_MB=000000
UNIT_KB=000
UNIT_B=

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
  typeset level="$1"
  shift
  typeset str="$@"
  TS=$(date +%Y-%m-%d\ %H:%M:%S)
  if [ $level -gt $LOG_LEVEL ]; then
      return
  fi
  case "$level" in
    0)
      echo "[${TS}][error]" "${str}" | tee -a $OUTLOG
      ;;
    1)
      echo "[${TS}][info]" "${str}" | tee -a $OUTLOG
      ;;
    2)
      echo "[${TS}][debug]" "${str}" | tee -a $OUTLOG
      ;;
    3)
      echo "[${TS}][trace]" "${str}" | tee -a $OUTLOG
      ;;
  esac
}

function RUN {
  typeset str="$@"
  LOG 2 "${str}"
  /bin/ksh -c "${str}"
}

# //common

# execute
function execute {
  LOG 3 "$@"
  typeset cmd
  for task in "$@"; do
    case $task in
    clear-log)
      cmd="find /root/bin -type f -size +1${UNIT_B}"
      LOG 2 $cmd
      set -A files $(/bin/ksh -c "${cmd}")
      typeset -a entries
      for file in "${files[@]}"; do
        if [[ "$file" == *" "* ]]; then
          LOG 0 "ERROR: filename contains spaces. $file"
          continue
        fi
        entries+=($file)
        LOG 1 $(ls -al ${file})
      done
      #for file in "${entries[@]}"; do
      #  RUN "cat /dev/null > $file"
      #done
      ;;
    kill-batch)
      #cmd="ps -ef | grep -v grep | grep btuser | grep JobRunnerMain | awk '{
      cmd="ps -ef | grep -v grep | grep -v awk | awk '{
        for (i=1; i<=NF; i++) {
          if (\$i ~ /\/usr/) {
            printf \"[%d] \", \$2
            for (j=i; j<=NF; j++) {
              printf \"%s \", \$j
            }
            printf \"\n\"
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

DEBUG_MODE=0
OPTIONS="h,d"
LONGOPTIONS="help,execute=*"
function main_gnu {
  opts=$( getopt --options "${OPTIONS}" \
                 --longoptions "${LONGOPTIONS}" \
                 -- "$@" )
  eval set -- "${opts}"

  while true; do
    if [ -z "$1" ]; then
      break
    fi
    echo "$1"
    case $1 in
    -h)
      USAGE
      ;;
    -d)
      DEBUG_MODE=1
      ;;
    --exec=*)
      echo "hello"
      local list="${1#--exec=}"
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
    --)
      ;;
    esac
    shift
  done
}

LOG_LEVEL=0
function main {
  typeset -a tasks=()
  while getopts "he:v" opt; do
    case "$opt" in
      h|\?)
        USAGE
        ;;
      v)
        LOG_LEVEL=$((LOG_LEVEL+1))
        echo "log level: ${LOG_LEVEL}"
        ;;
      e)
        tasks+=($OPTARG)
        ;;
    esac
  done
  echo "tasks: ${tasks[@]}"
  if [ ${#tasks[@]} -ge 0 ]; then
    execute "${tasks[@]}"
  fi
  shift $((OPTIND - 1))
}

main "$@"

