#!/bin/bash

BASHDIR=$( cd $( dirname $0 ) && pwd -P )

cat << EOF > ~/.bash_profile
#!/bin/bash

set -o vi

export JAVA_HOME="/c/develop/tools/java/openjdk-17.0.3.0.6-1"
PATH="\$JAVA_HOME/bin:\$PATH"
export MAVEN_HOME="/c/develop/tools/maven"
PATH="\$MAVEN_HOME/bin:\$PATH"
export GRADLE_HOME="/c/develop/tools/gradle"
PATH="\$GRADLE_HOME/bin:\$PATH"

PATH="$BASHDIR:\$PATH"
PATH="$BASHDIR/bin:\$PATH"
PATH="$BASHDIR/bin/bcomp:\$PATH"
PATH="$BASHDIR/backup:\$PATH"
PATH="$BASHDIR/docker:\$PATH"
PATH="$BASHDIR/build:\$PATH"
PATH="$BASHDIR/docker/kafka-connector:\$PATH"
export PATH

alias cdbash="cd '$BASHDIR'"
alias cdapp="cd '/c/project/spring-application'"
alias cddocker="cd '$BASHDIR'/docker"
alias cdweb="cd '/c/react/web-admin'"

alias backup='backup.sh develop project editplus bash'
alias restore='restore.sh develop project editplus bash'

EOF

echo "generated '~/.bash_profile'"

cat << EOF
[ env ]
  JAVA_HOME: $JAVA_HOME
  MAVEN_HOME: $MAVEN_HOME
  GRADLE_HOME: $GRADLE_HOME

[ alias ]

  alias cdbash="cd '$BASHDIR'"
  alias cdapp="cd '/c/project/spring-application'"
  alias cdfra="cd '/c/project/spring-framework'"
  alias cddocker="cd '$BASHDIR'/docker"
  alias cdweb="cd '/c/react/web-admin'"
  
  alias backup='backup.sh develop project editplus bash'
  alias restore='restore.sh develop project editplus bash'

EOF

