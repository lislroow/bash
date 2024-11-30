#!/bin/bash

FUNCDIR=$( cd "$( dirname "$0" )" && pwd -P )
BASEDIR=$( cd "$( dirname "$0" )" && cd .. && pwd -P )
PROP=$( bash -c "cat \"${FUNCDIR}/property.json\"" )
CURRDIR=$( pwd -P )

# usage
function USAGE {
  cat << EOF
- USAGE
Usage: ${0##*/} --target develop

EOF
  exit 1
}
# //usage

# options
OPTIONS="l"
LONGOPTIONS="target:"
eval "source \"$BASEDIR/common.sh\""
LIST_MODE=0
function SetOptions {
  opts=$( getopt --options "${_OPTIONS}",$OPTIONS \
                 --longoptions "${_LONGOPTIONS}",$LONGOPTIONS \
                 -- "$@" )
  eval set -- "${opts}"
  
  if [ "${DEBUG_MODE}" == "1" ]; then
    LOG "opts: " "${opts}"
  fi
  
  while true; do
    if [ -z "$1" ]; then
      break
    fi
    case $1 in
      -h | --help) ;;
      -v | --verbose) 
        DEBUG_MODE=1
      ;;
      --target)
        TARGET=$2
        if [ -n "${TARGET}" ]; then
          shift
        fi
        ;;
      --)
        ;;
      *)
        params+=("$1")
        ;;
    esac
    shift
  done
  
  if [ -z "${TARGET}" ]; then
    TARGET=develop
  fi
  
  if [ "${DEBUG_MODE}" == "1" ]; then
    cat << EOF
- SetOptions
  TARGET = ${TARGET}

EOF
  fi
}
SetOptions "$@"
# //options


# main
function main {
  mapfile -t includes < <(EXEC_R "jq -r '.archive.${TARGET}.includes[]' < ${FUNCDIR}/property.json")
  mapfile -t excludes < <(EXEC_R "jq -r '.archive.${TARGET}.excludes[]' < ${FUNCDIR}/property.json")
  
  basedir=$( GetProp "archive.${TARGET}.basedir" )
  spf=$( GetProp "archive.${TARGET}.spf" )
  
  OUTPUT_FILE=$(printf "%s_%s.zip" ${TARGET} $(date +%Y%m%d_%H%M%S))
  
  CMD="cd ${basedir} && 7z a ${CURRDIR}/${OUTPUT_FILE} ${includes[@]}"
  
  if [ ${#excludes[@]} -gt 0 ]; then
    CMD="${CMD} $(printf -- "-xr!\"%s\" " "${excludes[@]}")"
  fi
  
  if [ "${spf}" == 'true' ]; then
    CMD="${CMD} -spf"
  fi
  
  if [ "${DEBUG_MODE}" == "1" ]; then
    CMD="${CMD} -bb3"
  fi
  
  EXEC "${CMD}"
}

main
# //main

exit 0