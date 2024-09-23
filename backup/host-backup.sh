#!/bin/bash

#[ref]
# printf "\e[0;32m text \e[0m"

odir=$HOME
host=$(hostname)
ipaddr=$(ifconfig eth0 | sed -n 's|.*inet \([^ ]*\)  netmask.*|\1|p')
tarFile="${odir}/backup-${host}.tar"
gzFile=${tarFile}.gz
ouser=root

mapfile -t USER_LIST < <(cat <<- EOF
oracle
EOF
)

mapfile -t TARGET_LIST < <(cat <<- EOF
/etc/hosts
/etc/rc.d/init.d/oracledb_ORCLCDB-19c
/opt/oracle/product/19c/dbhome_1/network/admin
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
