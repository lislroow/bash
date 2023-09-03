#!/bin/bash

# VAR
CURRDIR=$( pwd -P )
FUNCFILE=$0
#FUNCDIR=$( cd $( dirname $0 ) && pwd -P )
FUNCDIR=${FUNCFILE%/*}
BASEDIR=${FUNCDIR%/*}
PROP=$( bash -c "cat \"$FUNCDIR/property.json\"" )
# //VAR

# usage
function USAGE {
  cat << EOF
- USAGE
Usage: $0 [options] <entries>

  ${0##*/} <entries>       : sync (storage-> backup)

EOF
  exit 1
}
# //usage

# options
OPTIONS="l"
LONGOPTIONS=""
eval "source \"$BASEDIR/common.sh\""
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
  STORAGE_DRV=$( GetProp "backup.storage" )
  
  if [ $DEBUG_MODE == 1 ]; then
    cat << EOF
- SetOptions
  OUTDIR = $OUTDIR
  STORAGE_DRV = $STORAGE_DRV

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
    printf " \e[1;36m%s\e[0m %s\n" "[$midx/$mtot] \"$entry\""
    row=$( jq -r '.backup.entries[] | select(.name == "'$entry'") | "\(.name)|\(.source)"' <<< $PROP | sed '' )
    IFS='|'; read name source <<< $row; unset IFS
    
    ### validation
    if [ ! -e "$STORAGE_DRV/@backup-sync/${source##*/}" ]; then
      LOG "\e[0;31merror\e[0m: \"$entry\" \"$STORAGE_DRV/@backup-sync/${source##*/}\" 가 존재하지 않습니다." 
      continue
    fi
    
    ### sync (storage-> backup)
    EXEC "bcomp @\"$FUNCDIR/sync-mirror.bc\" \"$STORAGE_DRV/@backup-sync/${source##*/}\" \"$OUTDIR/${source##*/}\""
    LOG "\e[0;32msource path:\e[0m" $source
    
    let "midx = midx + 1"
  done
}
main
# //main

exit 0
