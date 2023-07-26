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
OPTIONS="a,s"
LONGOPTIONS=""
source ../common.sh
ARCHIVE_MODE=0
STORAGE_MODE=0
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
      -a)
        ARCHIVE_MODE=1
        ;;
      -s)
        STORAGE_MODE=1
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
  ARCHIVE_MODE = $ARCHIVE_MODE
  STORAGE_MODE = $STORAGE_MODE

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
  IFS=","; read -a ENTRIES <<< ${params[*]}; unset IFS
  mtot=${#ENTRIES[*]}
  midx=1
  for entry in ${ENTRIES[*]}; do
    if [ $entry == 'all' ]; then
      ENTRIES=($( jq -r '.backup.entries[] | .name' <<< $PROP | sed '' ))
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
  for entry in ${ENTRIES[*]}; do
    printf " \e[1;37m%s\e[0m %s\n" "[$midx/$mtot] \"$entry\""
    row=$( jq -r '.backup.entries[] | select(.name == "'$entry'") | "\(.name)|\(.source)"' <<< $PROP | sed '' )
    IFS='|'; read name source <<< $row; unset IFS
    
    if [ ! -e "$source" ]; then
      LOG "\e[0;31merror\e[0m: \"$entry\" source 가 존재하지 않습니다." 
      continue
    fi
    
    output=$OUTDIR/${source##*/}
    
    EXEC "bcomp @\"$SCRDIR/bcomp.script\" \"$source\" \"$output\""
    
    if [ $ARCHIVE_MODE == 1 ]; then
      EXEC "cd $OUTDIR; tar cf \"${output}.tar\" ${source##*/}"
    fi
    
    if [ $STORAGE_MODE == 1 ]; then
      EXEC "bcomp @\"$SCRDIR/bcomp.script\" \"$source\" \"$STORAGE/${source##*/}\""
    fi
    
    if [ $STORAGE_MODE == 1 ] && [ $ARCHIVE_MODE == 1 ]; then
      EXEC "cd $OUTDIR; tar cvf - \"${output##*/}.tar\" | (cd \"$STORAGE\" ; tar xvf -)"
    fi
    
    let "midx = midx + 1"
  done
}
main
# //main

exit 0