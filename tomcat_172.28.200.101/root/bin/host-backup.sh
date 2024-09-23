#!/bin/bash

#[ref]
# printf "\e[0;32m text \e[0m"

odir=$HOME
host=$(hostname)
ipaddr=$(ifconfig eth | sed -n 's|.*inet \([^ ]*\)  netmask.*|\1|p')
tarFile="${odir}/backup-${host}.tar"
gzFile=${tarFile}.gz
ouser=root

mapfile -t USER_LIST < <(cat <<- EOF
EOF
)

mapfile -t TARGET_LIST < <(cat <<- EOF
/etc/hosts
/data
/sorc
/etc/logrotate.d
/etc/systemd/system/scouter-server.service
/etc/systemd/system/scouter-agent.host.service
/root/.bash_profile
/root/bin
EOF
)

function addFile {
  tarFile="$1"
  target="$2"
  if [ -e "${target}" ]; then
    printf "\e[0;32m [backup] tar rf ${tarFile} ${target} \e[0m"
    tar rf "${tarFile}" "${target}" 2> /dev/null
    printf " ... done\n"
  fi
}

for target in "${TARGET_LIST[@]}"; do
  addFile "${tarFile}" "${target}"
done

printf " compress ... "
gzip "${tarFile}"
printf "done%s" $'\n'
chown ${ouser}:${ouser} "${gzFile}"

printf "\e[0;32m [output] ${gzFile} \e[0m %s" $'\n'

#printf "\e[0;32m [backup] tar cf ${tarFile} --exclude 'tomcat' --exclude 'work' --exclude 'logs' /engn \e[0m"
#tar cf "${tarFile}" --exclude 'tomcat' --exclude 'work' --exclude 'logs' /engn 2> /dev/null
#if [ $? -eq 0 ]; then
#  printf "... done %s" $'\n'
#else
#  printf "... \e[0;32mError\e[0m %s" $'\n'
#fi
