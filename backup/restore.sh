#!/bin/bash

# usage
function USAGE {
  cat << EOF
- USAGE
Usage: $0 [options] <entries>
 -a   : 7z 아카이브 생성하기 (default: disabled)

sample:
  $0 [options] all             : 전체 실행
  $0 [options] develop itunes  : develop, itunes 실행

EOF
  exit 1
}
# //usage

# options
OPTIONS="l"
LONGOPTIONS=""
source ../common.sh
LIST_MODE=0
function SetOptions {
  opts=$( getopt --options $_OPTIONS,$OPTIONS \
                 --longoptions $_LONGOPTIONS,$LONGOPTIONS \
                 -- $* )
  eval set -- $opts
  while true; do
    if [ -z $1 ]; then
      break
    fi
    case $1 in
      -h | -v | --help | --verbose) ;;
      -l)
        LIST_MODE=1
        ;;
      --)
        ;;
      *)
        params+=($1)
        ;;
    esac
    shift
  done
  
  if [ -z "${params[*]}" ]; then
    USAGE
  fi
  
  OUTDIR=$( GetProp "backup.outdir" )
  STORAGE=$( GetProp "backup.storage" )
  
  if [ $DEBUG_MODE == 1 ]; then
    cat << EOF
- SetOptions
  OUTDIR = $OUTDIR
  STORAGE = $STORAGE

EOF
  fi
}
SetOptions $*
if [ $? -ne 0 ]; then
  USAGE
  exit 1
fi
# //options


# main
function main {
  ## prepare
  if [ $LIST_MODE == 1 ] || [ -z "${params[*]}" ]; then
    ENTRIES=($( jq -r '.backup.entries[] | .name' <<< $PROP | sed '' ))
    cat << EOF
  - main
    ENTRIES = [ ${ENTRIES[*]} ]

EOF
    USAGE
  fi
  
  ## entries
  IFS=","; read -a ENTRIES <<< ${params[*]}; unset IFS
  mtot=${#ENTRIES[*]}
  midx=1
  for entry in ${ENTRIES[*]}; do
    if [ $entry == 'all' ]; then
      ENTRIES=($( jq -r '.backup.entries[] | .name' <<< $PROP | sed '' ))
      mtot=${#list[*]}
      break
    fi
  done
  
  cat << EOF
- main
  params = ${params[*]}
  ENTRIES = [ ${ENTRIES[*]} ]
  mtot = $mtotd
  
EOF
  
  ## process
  for entry in ${ENTRIES[*]}; do
    printf " \e[1;37m%s\e[0m %s\n" "[$midx/$mtot] \"$entry\""
    row=$( jq -r '.backup.entries[] | select(.name == "'$entry'") | "\(.name)|\(.source)"' <<< $PROP | sed '' )
    IFS='|'; read name source <<< $row; unset IFS
    
    if [ ! -e "$STORAGE/${source##*/}" ]; then
      LOG "\e[0;31merror\e[0m: \"$entry\" \"$STORAGE/${source##*/}\" 가 존재하지 않습니다." 
      continue
    fi
    
    EXEC "bcomp @\"$SCRDIR/bcomp.script\" \"$STORAGE/${source##*/}\" \"$OUTDIR/${source##*/}\""
    
    let "midx = midx + 1"
  done
}
main
# //main

exit 0