#!/bin/ksh

LOG_LEVEL=0
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
      echo "[${TS}][error]" "${str}"
      ;;
    1)
      echo "[${TS}][info]" "${str}"
      ;;
    2)
      echo "[${TS}][debug]" "${str}"
      ;;
    3)
      echo "[${TS}][trace]" "${str}"
      ;;
  esac
}

function RUN {
  typeset str="$@"
  LOG 2 "${str}"
  /bin/ksh -c "${str}"
}
