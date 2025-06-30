#!/bin/ksh

LOG_LEVEL=0
_OPTIONS="hv"
function _init {
  while getopts "${_OPTIONS}${OPTIONS}" opt; do
    case "$opt" in
      h|\?)
        USAGE
        ;;
      v)
        LOG_LEVEL=$((LOG_LEVEL+1))
        ;;
    esac
  done
  shift $((OPTIND-1))
}

_init "$@"

function LOG {
  typeset -i level="$1"
  shift
  typeset str="$@"
  
  TS=$(date +%Y-%m-%d\ %H:%M:%S)
  if [ $level -gt "${LOG_LEVEL}" ]; then
      return
  fi
  case "$level" in
    0)
      echo "[${TS}][error]" "${str}" 1>&2
      ;;
    1)
      echo "[${TS}][info]" "${str}" 1>&2
      ;;
    2)
      echo "[${TS}][debug]" "${str}" 1>&2
      ;;
    3)
      echo "[${TS}][trace]" "${str}" 1>&2
      ;;
  esac
}

function RUN {
  typeset str="$@"
  LOG 2 "${str}"
  /bin/ksh -c "${str}"
}

function PRINT_LIST {
  set -A list="$@"
  for item in ${list[@]}; do
    LOG 2 "$item" 1>&2
  done
}
