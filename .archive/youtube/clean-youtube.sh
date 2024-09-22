#!/bin/bash

# VAR
CURRDIR=$( pwd -P )
FUNCFILE=$0
FUNCDIR=$( cd "$( dirname "$0" )" && pwd -P )
#FUNCDIR=${FUNCFILE%/*}
BASEDIR=${FUNCDIR%/*}
PROP=$( bash -c "cat \"$FUNCDIR/property.json\"" )
# //VAR

# usage
function USAGE {
  cat << EOF
- USAGE
Usage: $0 [options] <entries>

EOF
  exit 1
}
# //usage

# options
OPTIONS="l,a,s"
LONGOPTIONS=""
eval "source \"$BASEDIR/common.sh\""
LIST_MODE=0
function SetOptions {
  opts=$( getopt --options "${_OPTIONS}","${OPTIONS}" \
                 --longoptions "${_LONGOPTIONS}","${LONGOPTIONS}" \
                 -- "$@" )
  eval set -- "${opts}"
  
  if [ "${DEBUG_MODE}" == "1" ]; then
    LOG "opts: " "${opts}"
  fi
  
  while true; do
    if [ -z "$1" ]; then
      break
    fi
    case "$1" in
      -h | -v | --help | --verbose) ;;
      -l)
        LIST_MODE=1
        ;;
      --)
        ;;
      *)
        params+=("$1")
        ;;
    esac
    shift
  done
  
  if [ "${DEBUG_MODE}" == "1" ]; then
    cat << EOF
- SetOptions

EOF
  fi
}
SetOptions "$@"
if [ $? -ne 0 ]; then
  USAGE
  exit 1
fi
# //options


# main
function main {
  ## prepare
  if [ $LIST_MODE == 1 ] || [ -z "${params[*]}" ]; then
    #ENTRIES=($( jq -r '.clear.entries[] | .name' <<< $PROP | sed '' ))
    mapfile -t ENTRIES < <( jq -r '.clear.entries[] | .name' <<< "${PROP}" | sed '' )
    cat << EOF
- main
  ENTRIES = [ ${ENTRIES[*]} ]

EOF
    #USAGE
    exit 0
  fi
  
  ## entries
  IFS=","; read -r -a ENTRIES <<< "${params[@]}"; unset IFS
  mtot=${#ENTRIES[*]}
  midx=1
  for entry in "${ENTRIES[@]}"; do
    if [ "${entry}" == 'all' ]; then
      #ENTRIES=($( jq -r '.clear.entries[] | .name' <<< $PROP | sed '' ))
      mapfile -t ENTRIES < <( jq -r '.clear.entries[] | .name' <<< "${PROP}" | sed '' )
      mtot=${#ENTRIES[*]}
      break
    fi
  done
  
  cat << EOF
- main
  params = ${params[*]}
  ENTRIES = [ ${ENTRIES[*]} ]
  mtot = $mtot

EOF
  
  
  ## process
  targetdir=$( GetProp "clear.targetdir" )
  
  for entry in "${ENTRIES[@]}"; do
    printf " \e[1;36m%s\e[0m %s\n" "[$midx/$mtot]" "\"$entry\""
    row=$( jq -r '.clear.entries[] | select(.name|contains("'"${entry}"'")) | "\(.name)"' <<< "${PROP}" | sed '' )
    IFS='|'; read -r name <<< "${row}"; unset IFS
    
    ### list
    directory="${targetdir}/${name}_raw"
    if [ ! -e "${directory}" ]; then
      LOG "\e[0;31merror\e[0m: \"$directory\" 가 존재하지 않습니다."
      continue
    fi
    IFS=$'\n'
    #list=($( cd $directory; find . -type f -size +0 ))
    mapfile -t list < <( cd "${directory:?}" || continue; find . -type f -size +0 )
    local _tot=${#list[*]}
    local _idx=1
    for item in "${list[@]}"; do
      item=${item:2}
      EXEC "cat /dev/null > \"$directory/$item\""
      #let "_idx = _idx + 1"
      ((_idx+1))
    done
    #let "midx = midx + 1"
    ((midx + 1))
  done
}
main
# //main

exit 0