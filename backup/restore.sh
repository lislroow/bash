#!/bin/bash

# VAR
CURRDIR=$( pwd -P )
#FUNCFILE=${FUNCFILE#*/}
FUNCDIR=$( cd $( dirname $0 ) && pwd -P )
BASEDIR=$( cd $( dirname $0 ) && cd .. && pwd -P )

PROP=$( bash -c "cat \"$FUNCDIR/property.json\"" )
# //VAR

# usage
function USAGE {
  cat << EOF
- USAGE
Usage: ${0##*/} [options] <entries>

  ${0##*/} <entries>       : sync (storage-> backup)

EOF
  exit 1
}
# //usage

# options
OPTIONS="l"
LONGOPTIONS="drive:"
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
      --drive)
        DRIVE=$2
        if [ ! -z $DRIVE ]; then
          if [[ $DRIVE != '/'* ]]; then
            DRIVE="/$DRIVE"
          fi
          if [ ! -e $DRIVE ]; then
            LOG "\e[0;31merror\e[0m: \"DRIVE\" \"$DRIVE\" 가 존재하지 않습니다."
            exit 1
          fi
          shift
        fi
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
  if [ -z $DRIVE ]; then
    DRIVE=$( GetProp "backup.drive" )
  fi
  
  if [ $DEBUG_MODE == 1 ]; then
    cat << EOF
- SetOptions
  OUTDIR = $OUTDIR
  DRIVE = $DRIVE

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
    ENTRIES=($(EXEC_R "cat $FUNCDIR/property.json | jq -r '.backup.entries[] | .name' | sed ''"))
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
      ENTRIES=($(EXEC_R "cat $FUNCDIR/property.json | jq -r '.backup.entries[] | .name' | sed ''"))
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
    row=$(EXEC_R "cat $FUNCDIR/property.json | jq -r '.backup.entries[] | select(.name == \"$entry\") | \"\(.name)|\(.source)|\(.storageOnly)\"' | sed ''")
    IFS='|'; read name source storageOnly <<< $row; unset IFS
    
    if [ $storageOnly == 'true' ]; then
      LOG "\e[0;32m\"$entry\": storageOnly == 'true'\e[0m" $source
      continue
    fi
    
    ### validation
    if [ ! -e "$DRIVE/${source##*/}" ]; then
      LOG "\e[0;31merror\e[0m: \"$entry\" \"$DRIVE/${source##*/}\" 가 존재하지 않습니다." 
      continue
    fi
    
    ### sync (storage-> source)
    EXEC "bcomp @\"$FUNCDIR/sync-mirror.bc\" \"$DRIVE/${source##*/}\" \"$source\""
    
    let "midx = midx + 1"
  done
}
main
# //main

exit 0
