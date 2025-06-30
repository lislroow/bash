#!/bin/ksh
BASEDIR=$(cd "$(dirname "$0")" && pwd -P)
SYSNAME=$(uname -a | awk '{ print $1 }')

# common
function USAGE {
  cat <<EOF
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
if [ "${LOG_LEVEL}" -eq 0 ]; then
  LOG_LEVEL=1
fi
typeset SIZE="+100000c"
typeset MMIN
typeset MTIME="+1"
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
  shift $((OPTIND-1))
}

init "$@"
# -- init

LOG 2 "== script started"
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
  
  ## 파일 검색
  typeset str="find /logs ${FIND_COND}"
  LOG 1 "$str"
  set -A list -- $(eval "$str")
  
  ## 함수 반환
  echo ${list[@]}
}

function ProcessFiles {
  set -A list -- "$@"
  typeset -i cnt=0
  for item in ${list[@]}; do
    typeset str
    #if [[ "${item}" =~ \.gz$ ]]; then
    #  LOG 1 "(exclude) gz file, ${item}"
    #fi
    if [ $(expr "${item}" : ".*\.gz") -gt 0 ]; then
      LOG 1 "(exclude) gz file, ${item}"
    fi
    if [ -e "${item}.gz" ]; then
      LOG 1 "(exclude) already exist, ${item}.gz"
    else
      str="gzip -c ${item} > ${item}.gz"
      RUN $str
    fi
    str="tail -n 4000 ${item} > temp.log && cat /dev/null > ${item} && cat temp.log > ${item}"
    LOG 2 "$str"
    /bin/ksh -c "$str"
    if [ $? -eq 0 ]; then
      cnt=$((cnt+1))
    fi
  done
  LOG 1 "${cnt} 개 파일이 정리되었습니다."
}

set -A list -- $(`FindLogFiles`)

printf "───────────────────────────────────────────────────────────────\n"
printf "* 정리대상: %s개\n" "${#list[@]}"
typeset -i i=1
for item in ${list[@]}; do
  printf "  %s) %s\n" "$i" "$(ls -al ${item})"
  i=$((i+1))
done
printf "───────────────────────────────────────────────────────────────\n"

if [ ${ARCHIVE_YN} -eq 1 ] || [ ${TRUNCATE_YN} -eq 1 ]; then
  ProcessFiles "${list[@]}"
else
  if [ "${#list[@]}" -gt 0 ]; then
    printf "%s" "${#list[@]} 개의 파일을 삭제하시겠습니까? [y/n] "
    read yn
    if [ "${yn}" == "y" ]; then
      ProcessFiles "${list[@]}"
    fi
  fi
fi
# -- main

END_TIME=$(date +%s)
ELAPSED_TIME=$((END_TIME - START_TIME))
LOG 2 "== script completed (elapsed time: ${ELAPSED_TIME})"
