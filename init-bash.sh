#!/bin/bash

BASHDIR=$( cd $( dirname $0 ) && pwd -P )

cat << EOF > ~/.bash_profile
#!/bin/bash

PATH="$BASHDIR:\$PATH"
PATH="/c/.tools/mkvtoolnix:\$PATH"
PATH="$BASHDIR/bin:\$PATH"
PATH="$BASHDIR/bin/bcomp:\$PATH"
PATH="$BASHDIR/backup:\$PATH"
PATH="$BASHDIR/youtube:\$PATH"
export PATH

alias gobash="cd '$BASHDIR'"
alias gospring="cd '/c/project/spring'"

alias backup-d='backup.sh --drive=d itunes 유틸리티 develop project wallpaper editplus'

EOF

echo "generated '~/.bash_profile'"

cat << EOF
[ git clone ]

  $ git clone https://github.com/lislroow/spring

[ alias ]

  alias gobash="cd '$BASHDIR'"
  alias gospring="cd '/c/project/spring'"
  
  alias backup-d='backup.sh --drive=d itunes 유틸리티 develop project wallpaper editplus'

EOF

