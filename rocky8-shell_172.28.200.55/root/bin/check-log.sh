#!/bin/ksh
BASEDIR=$( cd "$( dirname "$0" )" && pwd -P )
SYSNAME=$(uname -a | awk '{ print $1 }')

# common
function USAGE {
  cat << EOF
───────────────────────────────────────────────────────────────
Usage:
-s:  s 크기(size) 파일을 선택합니다.
     s는 find 명령어에 전달되는 값입니다.
-m:  분(min) 지난 파일을 선택합니다.
     m 은 find 명령어에 전달되는 값입니다.
-d:  일(day) 지난 파일을 선택합니다.
     d 는 find 명령어에 전달되는 값입니다.
-a:  선택된 파일을 .gz 으로 압축(archive) 합니다.
-t   선택된 파일을 truncate 합니다.
     선택된 파일을 0byte 로 truncate 합니다.
───────────────────────────────────────────────────────────────
EOF
  exit 1
}
OPTIONS="s:m:d:at"
source ${BASEDIR}/common.inc
# -- common


# init
typeset SIZE
typeset MMIN
typeset MTIME
typeset ARCHIVE_YN=0
typeset TRUNCATE_YN=0

function init {
  while getopts "${_OPTIONS},${OPTIONS}" opt; do
    case "$opt" in
      s)
        SIZE=${OPTARG}
        ;;
      m)
        MMIN=${OPTARG}
        ;;
      d)
        MTIME=${OPTARG}
        ;;
      a)
        ARCHIVE_YN=1
        ;;
      t)
        TRUNCATE_YN=1
        ;;
    esac
  done
  shift $((OPTIND - 1))
}

init "$@"
# -- init

LOG 1 "== script started"
START_TIME=$(date +%s)

# main
function FindLogFiles {
  typeset FIND_COND="-type f ! -name '*.gz'"
  if [ -n "${SIZE}" ]; then
    FIND_COND="${FIND_COND} -size ${SIZE}"
  fi
  if [ -n "${MMIN}" ]; then
    FIND_COND="${FIND_COND} -mmin ${MMIN}"
  fi
  if [ -n "${MMIN}" ] && [ -n "${MTIME}" ]; then
    FIND_COND="${FIND_COND} -o"
  fi
  if [ -n "${MTIME}" ]; then
    FIND_COND="${FIND_COND} -mtime ${MTIME}"
  fi
  typeset str="find /logs ${FIND_COND}"
  LOG 1 $str
  typeset -a list=(`$str`)
  echo ${list[@]}
}

function ProcessFiles {
  list="$@"
  for item in ${list[@]}; do
    typeset str
    if [[ "${item}" =~ \.gz$ ]]; then
      LOG 1 "(exclude) gz file, ${item}"
    fi
    if [ -e "${item}.gz" ]; then
      LOG 1 "(exclude) already exist, ${item}.gz"
    else
      str="gzip -c ${item} > ${item}.gz"
      RUN $str
    fi
    str="tail -n 4000 ${item} > temp.log && cat /dev/null > ${item} && cat temp.log > ${item}"
    LOG 1 $str
  done
}

list=(`FindLogFiles`)
PRINT_LIST ${list[@]}

if [ ${ARCHIVE_YN} == 1 ] || [ ${TRUNCATE_YN} == 1 ]; then
  ProcessFiles "${list[@]}"
fi
# -- main

END_TIME=$(date +%s)
ELPASED_TIME=$((END_TIME - START_TIME))
LOG 1 "== script completed (elapsed time: ${ELPASED_TIME})"
