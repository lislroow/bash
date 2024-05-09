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
PATH="$BASHDIR/docker:\$PATH"
PATH="$BASHDIR/build:\$PATH"
PATH="$BASHDIR/youtube:\$PATH"
PATH="$BASHDIR/docker/kafka-connector:\$PATH"
export PATH

alias cdbash="cd '$BASHDIR'"
alias cdapp="cd '/c/project/spring-application'"
alias cdfram="cd '/c/project/spring-framework'"
alias cddocker="cd '/c/project/bash/docker'"

alias backup='backup.sh --drive=d itunes 유틸리티 develop project wallpaper editplus;\
              backup.sh --drive=y itunes 유틸리티 develop project'

EOF

echo "generated '~/.bash_profile'"

cat << EOF
[ env ]
  JAVA_HOME: $JAVA_HOME
  MAVEN_HOME: $MAVEN_HOME

[ alias ]

  alias cdbash="cd '$BASHDIR'"
  alias cdapp="cd '/c/project/spring-application'"
  alias cdfram="cd '/c/project/spring-framework'"
  alias cddocker="cd '/c/project/bash/docker'"
  
  alias backup='backup.sh --drive=d itunes 유틸리티 develop project wallpaper editplus;\
                backup.sh --drive=y itunes 유틸리티 develop project'

EOF

