#!/bin/env bash

FUNCDIR=$( cd "$( dirname "$0" )" && pwd -P )
BASEDIR=$( cd "$( dirname "$0" )" && cd .. && pwd -P )
PROP=$( bash -c "cat \"${FUNCDIR}/property.json\"" )
CURRDIR=$( pwd -P )

source $BASEDIR/common.sh

# usage
function USAGE {
  cat << EOF
- USAGE
Usage: ${0##*/} --target develop

EOF
  exit 1
}
# -- usage

# options
OPTIONS="h"
declare LONGOPTIONS=""
declare opts=$(getopt --options "${OPTIONS}" \
                      --longoptions "${LONGOPTIONS}" \
                      -- "$@" )
eval set -- "${opts}"
while true; do
  [[ -z $1 ]] && break
  
  case "$1" in
    -h)
      USAGE
      ;;
    --)
      ;;
    --*)
      printf "[%-5s] %s\n" "ERROR" "invalid option: '$1'"
      exit
      ;;
    *)
      argv+=($1)
      ;;
  esac
  shift
done
# -- options

# argv
for arg in ${argv[@]}; do
  case "${arg}" in
    target=*)
      values=${arg#target=}
      IFS=',' read -ra targets <<< "${values}"
      ;;
  esac
done
# -- argv

# archive
function archive {
  local target timestamp tool ext ofile ofile_tmp cmd_str
  
  target=$1
  timestamp=$(date +%Y%m%d_%H%M)
  tool="7z"
  # tool="tar"
  # tool="zstd"
  case ${tool} in
    7z)
      ext="zip"
      ;;
    tar)
      ext="tar"
      ;;
    zstd)
      ext="zstd"
      ;;
  esac
  ofile="${target}.${ext}"
  ofile_tmp="${target}_${timestamp}.${ext}"
  cmd_str="cd C:/ && 7z a -spf ${CURRDIR}/${ofile_tmp}"
  # cmd_str="cd C:/ && tar cvf ${CURRDIR}/${ofile_tmp}"
  # cmd_str="cd C:/ && zstd -r -T0 -19 -o ${CURRDIR}/${ofile_tmp}"
  
  mapfile -t includes < <(EXEC_R "jq -r '.archive.${target}.includes[]' < ${FUNCDIR}/property.json")
  if (( ${#includes[@]} > 0 )); then
    for p in ${includes[@]}; do
      if [[ "$p" =~ ^[A-Za-z]:/ ]]; then
        drive=$(echo "${p:0:1}" | tr '[:upper:]' '[:lower:]')
        path_rest="${p:2}"
        path_unix="/$drive$path_rest"
      else
        path_unix=$(eval "echo $p")
      fi
      path_clean="${path_unix#/c/}"
      cmd_str+=" ${path_clean}"
    done
  fi
  
  mapfile -t excludes < <(EXEC_R "jq -r '.archive.${target}.excludes[]' < ${FUNCDIR}/property.json")
  if (( ${#excludes[@]} > 0 )); then
    exclude_opts=$(printf -- " -xr!\"%s\"" "${excludes[@]}")
    cmd_str+=" ${exclude_opts}"
  fi
  
  EXEC "${cmd_str}"
  
  # if [[ ${target} == "develop" ]]; then
  #   cmd_str="7z rn ${ofile_tmp}"
  #   cmd_str+=" C:/develop develop_${timestamp}"
  #   cmd_str+=" C:/Users Users_${timestamp}"
  #   EXEC "${cmd_str}"
  # fi
  # mv "${ofile_tmp}" "${ofile}"
}

if (( ${#targets[@]} == 0 )); then
  targets="develop"
fi

for target in ${targets[@]}; do
  archive "${target}"
done
# -- archive

exit 0