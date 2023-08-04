#!/bin/bash

BASHDIR=$( cd $( dirname $0 ) && pwd -P )

cat << EOF > ~/.bash_profile
#!/bin/bash

PATH="$BASHDIR:\$PATH"
PATH="$BASHDIR/bin:\$PATH"
PATH="$BASHDIR/bin/bcomp:\$PATH"
PATH="$BASHDIR/backup:\$PATH"
export PATH

alias gobash="cd '$BASHDIR'"
alias gospring="cd '/c/project/spring'"

EOF

echo "generated '~/.bash_profile'"

cat << EOF
[ git clone ]

  $ git clone https://github.com/lislroow/spring

[ alias ]

  alias gobash="cd '$BASHDIR'"
  alias gospring="cd '/c/project/spring'"

EOF

