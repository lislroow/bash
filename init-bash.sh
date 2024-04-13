#!/bin/bash

BASHDIR=$( cd $( dirname $0 ) && pwd -P )

cat << EOF > ~/.bash_profile
#!/bin/bash

set -o vi

export JAVA_HOME="/c/develop/tools/java/openjdk-17.0.3.0.6-1"
PATH="\$JAVA_HOME/bin:\$PATH"
export MAVEN_HOME="/c/develop/tools/maven"
PATH="\$MAVEN_HOME/bin:\$PATH"

PATH="$BASHDIR:\$PATH"
PATH="/c/.tools/mkvtoolnix:\$PATH"
PATH="$BASHDIR/bin:\$PATH"
PATH="$BASHDIR/bin/bcomp:\$PATH"
PATH="$BASHDIR/backup:\$PATH"
PATH="$BASHDIR/youtube:\$PATH"
export PATH

alias cdbash="cd '$BASHDIR'"
alias cdbackend="cd '/c/project/backend'"
alias cdfrontend="cd '/c/project/frontend'"
alias cddocker="cd '/c/project/docker'"

alias backup='backup.sh --drive=d itunes 유틸리티 develop project wallpaper editplus;\
              backup.sh --drive=y itunes 유틸리티 develop project'

EOF

echo "generated '~/.bash_profile'"

cat << EOF
[ env ]
  JAVA_HOME: $JAVA_HOME
  MAVEN_HOME: $MAVEN_HOME

[ git clone ]

  $ git clone https://github.com/lislroow/backend

[ alias ]

  alias cdbash="cd '$BASHDIR'"
  alias cdbackend="cd '/c/project/backend'"
  alias cdbackend="cd '/c/project/backend'"
  alias cdfrontend="cd '/c/project/frontend'"
  alias cddocker="cd '/c/project/docker'"
  
  alias backup='backup.sh --drive=d itunes 유틸리티 develop project wallpaper editplus;\
                backup.sh --drive=y itunes 유틸리티 develop project'

EOF

