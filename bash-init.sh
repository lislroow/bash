#!/bin/bash

BASEDIR=$( cd $( dirname $0 ) && pwd -P )

cat << EOF > ~/.bash_profile
#!/bin/bash

PATH="\$PATH:$BASEDIR"
PATH="\$PATH:$BASEDIR/bin"
PATH="\$PATH:$BASEDIR/bin/bcomp"
PATH="\$PATH:$BASEDIR/backup"
export PATH
EOF

source ~/.bash_profile
