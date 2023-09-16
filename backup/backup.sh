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
 -l            : <entries> 보기
 -a            : 백업 디렉토리 tar 생성하기
 -s            : 스토리지 복사하기
 --outdir      : 백업 디렉토리 지정
 --drive : 스토리지 드라이브 지정

  ${0##*/} <entries>       : sync (source-> backup)
  ${0##*/} -a <entries>    : sync (source-> backup) + tar (backup)
  ${0##*/} -s <entries>    : sync (source-> backup) + sync (backup-> storage)
  ${0##*/} -s -a <entries> : sync (source-> backup) + sync (backup-> storage) + tar (backup) + cp (storage) 

EOF
  exit 1
}
# //usage

# options
OPTIONS="l,a,s"
LONGOPTIONS="outdir:,drive:"
eval "source \"$BASEDIR/common.sh\""
LIST_MODE=0
ARCHIVE_MODE=0
function SetOptions {
  opts=$( getopt --options $_OPTIONS,$OPTIONS \
                 --longoptions $_LONGOPTIONS,$LONGOPTIONS \
                 -- $* )
  eval set -- $opts
  
  if [ $DEBUG_MODE == 1 ]; then
    LOG "opts: " $opts
  fi
  
  while true; do
    if [ -z $1 ]; then
      break
    fi
    case $1 in
      -h | -v | --help | --verbose) ;;
      -l)
        LIST_MODE=1
        ;;
      #-a)
      #  ARCHIVE_MODE=1
      #  ;;
      --outdir)
        OUTDIR=$2
        if [ ! -z $OUTDIR ]; then
          if [[ $OUTDIR != '/'* ]]; then
            OUTDIR="/c/$OUTDIR"
          fi
          if [ ! -e $OUTDIR ]; then
            LOG "\e[0;31merror\e[0m: \"OUTDIR\" \"$OUTDIR\" 디렉토리가 존재하지 않습니다."
            exit 1
          fi
          shift
        fi
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
  
  if [ -z $OUTDIR ]; then
    OUTDIR=$( GetProp "backup.outdir" )
  fi
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
    ENTRIES=($( jq -r '.backup.entries[] | .name' <<< $PROP | sed '' ))
    cat << EOF
- main
  ENTRIES = [ ${ENTRIES[*]} ]

EOF
    #USAGE
    exit 0
  fi
  
  ## entries
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
    printf " \e[1;36m%s\e[0m %s\n" "[$midx/$mtot] \"$entry\""
    row=$( jq -r '.backup.entries[] | select(.name == "'$entry'") | "\(.name)|\(.source)|\(.storageOnly)|\(.bcScript)"' <<< $PROP | sed '' )
    IFS='|'; read name source storageOnly bcScript <<< $row; unset IFS
    
    ### validation
    if [ ! -e "$source" ]; then
      LOG "\e[0;31merror\e[0m: \"$entry\" \"$source\" 가 존재하지 않습니다." 
      continue
    fi
    
    if [ $bcScript == "null" ]; then
      bcScript="sync-mirror.bc"
    fi
    
    ### sync
    {
      ### sync (source-> backup)
      #if [ $storageOnly != 'true' ]; then
      #  EXEC "bcomp @\"$FUNCDIR/$bcScript\" \"$source\" \"$OUTDIR/${source##*/}\""
      #fi
      
      ### sync (backup -> storage)
      EXEC "bcomp @\"$FUNCDIR/$bcScript\" \"$source\" \"$DRIVE/${source##*/}\""
    }
    
    ### tar
    #{
    #  ### tar (backup)
    #  if [ $ARCHIVE_MODE == 1 ]; then
    #    EXEC "cd $OUTDIR; tar cf \"$OUTDIR/${source##*/}.tar\" \"${source##*/}\""
    #  fi
    #  
    #  ### cp (storage)
    #  if [ -e $OUTDIR/${source##*/}.tar ]; then
    #    EXEC "cp \"$OUTDIR/${source##*/}.tar\" \"$DRIVE/${source##*/}.tar\""
    #    EXEC "bcomp @\"$FUNCDIR/sync-mirror.bc\" \"$OUTDIR/${source##*/}.tar\" \"$DRIVE/${source##*/}.tar\""
    #  fi
    #}
    
    #((midx++))
    let "midx = midx + 1"
  done
}
main
# //main

exit 0