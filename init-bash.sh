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

alias cdbash="cd '$BASHDIR'"
alias cdbackend="cd '/c/project/backend'"

alias backup='backup.sh --drive=d itunes 유틸리티 develop project wallpaper editplus;\
              backup.sh --drive=y itunes 유틸리티 develop project'

EOF

echo "generated '~/.bash_profile'"

cat << EOF
[ git clone ]

  $ git clone https://github.com/lislroow/backend

[ alias ]

  alias cdbash="cd '$BASHDIR'"
  alias cdbackend="cd '/c/project/backend'"
  
  alias backup='backup.sh --drive=d itunes 유틸리티 develop project wallpaper editplus;\
                backup.sh --drive=y itunes 유틸리티 develop project'

EOF

