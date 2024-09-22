#!/bin/bash

# VAR
#CURRDIR=$( pwd -P )
#FUNCFILE=${FUNCFILE#*/}
FUNCDIR=$( cd "$( dirname "$0" )" && pwd -P )
BASEDIR=$( cd "$( dirname "$0" )" && cd .. && pwd -P )
PROP=$( bash -c "cat \"$FUNCDIR/property.json\"" )
# //VAR

# usage
function USAGE {
  cat << EOF
- USAGE
Usage: ${0##*/} [options] <entries>
 -l            : <entries> 보기
 -a            : 백업 디렉토리 tar 생성하기
 --drive : 스토리지 드라이브 지정

  ${0##*/} <entries>       : sync (source-> backup)

EOF
  exit 1
}
# //usage

# options
OPTIONS="l,a,s"
LONGOPTIONS="drive:,tar"
eval "source \"$BASEDIR/common.sh\""
LIST_MODE=0
TAR_MODE=0
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
      -h | -v | --help | --verbose) ;;
      -l)
        LIST_MODE=1
        ;;
      --tar)
        TAR_MODE=1
        ;;
      --outdir)
        OUTDIR=$2
        if [ -n "${OUTDIR}" ]; then
          if [[ "${OUTDIR}" != '/'* ]]; then
            OUTDIR="/c/$OUTDIR"
          fi
          if [ ! -e "${OUTDIR}" ]; then
            LOG "\e[0;31merror\e[0m: \"OUTDIR\" \"$OUTDIR\" 디렉토리가 존재하지 않습니다."
            exit 1
          fi
          shift
        fi
        ;;
      --drive)
        DRIVE=$2
        if [ -n "${DRIVE}" ]; then
          if [[ $DRIVE != '/'* ]]; then
            DRIVE="/$DRIVE"
          elif [ ! -e "${DRIVE}" ]; then
            LOG "\e[0;31merror\e[0m: \"DRIVE\" \"$DRIVE\" 가 존재하지 않습니다."
            exit 1
          fi
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
  
  if [ -z "${OUTDIR}" ]; then
    OUTDIR=$( GetProp "backup.outdir" )
  fi
  if [ -z "${DRIVE}" ]; then
    DRIVE=$( GetProp "backup.drive" )
  fi
  
  if [ "${DEBUG_MODE}" == "1" ]; then
    cat << EOF
- SetOptions
  OUTDIR = $OUTDIR
  DRIVE = $DRIVE

EOF
  fi
}
SetOptions "$@"
# //options


# main
function main {
  ## prepare
  if [ $LIST_MODE == 1 ] || [ -z "${params[*]}" ]; then
    #ENTRIES=($(EXEC_R "cat $FUNCDIR/property.json | jq -r '.backup.entries[] | .name' | sed ''"))
    mapfile -t ENTRIES < <(EXEC_R "cat $FUNCDIR/property.json | jq -r '.backup.entries[] | .name' | sed ''")
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
      #ENTRIES=($(EXEC_R "cat $FUNCDIR/property.json | jq -r '.backup.entries[] | .name' | sed ''"))
      mapfile -t ENTRIES < <(EXEC_R "cat $FUNCDIR/property.json | jq -r '.backup.entries[] | .name' | sed ''")
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
  for entry in "${ENTRIES[@]}"; do
    printf " \e[1;36m%s\e[0m %s\n" "[$midx/$mtot]" "\"$entry\""
    row=$(EXEC_R "cat $FUNCDIR/property.json | jq -r '.backup.entries[] | select(.name == \"$entry\") | \"\(.name)|\(.source)|\(.bcscript)\"' | sed ''")
    
    IFS='|'; read -r name source bcscript <<< "${row}"; unset IFS
    
    ### validation
    if [ ! -e "$source" ]; then
      LOG "\e[0;31merror\e[0m: \"$entry\" \"$source\" 가 존재하지 않습니다." 
      continue
    fi
    
    if [ "${bcscript}" == "null" ]; then
      bcscript="sync-mirror.bc"
    fi
    
    ### sync
    {
      ### sync (backup -> storage)
      case "${entry}" in
        project)
          if [ $TAR_MODE == 1 ]; then
            EXEC "mv /d/project /d/project_tmp"
            EXEC "tar cfz - --exclude 'node_modules' --exclude 'target' /c/${entry} | tar zxvf - --strip-components=1 -C /d/"
            EXEC "rm -rf /d/project_tmp"
          else
            EXEC "bcomp @\"$FUNCDIR/$bcscript\" \"$source\" \"$DRIVE/${source##*/}\""
          fi
          ;;
        *)
          EXEC "bcomp @\"$FUNCDIR/$bcscript\" \"$source\" \"$DRIVE/${source##*/}\""
          ;;
      esac
    }
    
    ((midx++))
    #let "midx = midx + 1"
  done
}
main
# //main

exit 0