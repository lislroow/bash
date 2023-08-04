#!/bin/bash

BASEDIR=$( cd $( dirname $0 ) && pwd -P )

cat << EOF > ~/.bash_profile
#!/bin/bash

PATH="$BASEDIR:\$PATH"
PATH="$BASEDIR/bin:\$PATH"
PATH="$BASEDIR/bin/bcomp:\$PATH"
PATH="$BASEDIR/backup:\$PATH"
export PATH

BASEDIR='$BASEDIR'
echo BASEDIR=$BASEDIR
alias gobase="cd '$BASEDIR'"

EOF

cat << EOF
generated "~/.bash_profile" file
type "source ~/.bash_profile"

EOF

