#!/bin/bash

BASHDIR=$( cd $( dirname $0 ) && pwd -P )

cat << EOF > ~/.bash_profile
#!/bin/bash

set -o vi

export LANG=ko_KR.utf8

export JAVA8="/c/develop/tools/java/corretto-8.422.05.1"
export JAVA11="/c/develop/tools/java/corretto-11.0.24.8.1"
export JAVA17="/c/develop/tools/java/corretto-17.0.12.7.1"
export JAVA21="/c/develop/tools/java/corretto-21.0.4.7.1"
export JAVA_HOME="\$JAVA17"
PATH="\$JAVA_HOME/bin:\$PATH"
export MAVEN_HOME="/c/develop/tools/maven/maven-3.8.8"
PATH="\$MAVEN_HOME/bin:\$PATH"
export GRADLE_HOME="/c/develop/tools/gradle"
PATH="\$GRADLE_HOME/bin:\$PATH"
export SPRING23="/c/develop/tools/spring/spring-2.3.8.RELEASE"
export SPRING27="/c/develop/tools/spring/spring-2.7.18"
export SPRING3="/c/develop/tools/spring/spring-3.3.3"
PATH="\$SPRING3/bin:\$PATH"

PATH="$BASHDIR:\$PATH"
PATH="$BASHDIR/bin:\$PATH"
PATH="$BASHDIR/bin/bcomp:\$PATH"
PATH="$BASHDIR/backup:\$PATH"
PATH="$BASHDIR/docker:\$PATH"
PATH="$BASHDIR/build:\$PATH"
PATH="$BASHDIR/docker/kafka-connector:\$PATH"
PATH="$BASHDIR/nginx:/c/develop/tools/nginx:\$PATH"
export PATH

alias curl="curl -s"
alias cdbash="cd '$BASHDIR'"
alias cdapp="cd '/c/project/spring-application'"
alias cddocker="cd '$BASHDIR'/docker"
alias cdweb="cd '/c/react/web-admin'"
alias cdhugo="cd '/c/linux/hugo/memo'"
alias cdnginx="cd '/c/develop/tools/nginx'"
alias gitlog="git log --oneline"

alias backup='backup.sh develop project editplus react hyper-v python linux'
alias restore='restore.sh develop project editplus react hyper-v python linux'

EOF

echo "generated '~/.bash_profile'"

cat << EOF
[ env ]
  LANG: $LANG
  JAVA_HOME: $JAVA_HOME
  JAVA8: $JAVA8
  JAVA11: $JAVA11
  JAVA17: $JAVA17
  JAVA21: $JAVA21
  MAVEN_HOME: $MAVEN_HOME
  GRADLE_HOME: $GRADLE_HOME

[ alias ]

  alias cdbash="cd '$BASHDIR'"
  alias cdapp="cd '/c/project/spring-application'"
  alias cdfra="cd '/c/project/spring-framework'"
  alias cddocker="cd '$BASHDIR'/docker"
  alias cdweb="cd '/c/react/web-admin'"
  alias cdhugo="cd '/c/linux/hugo/memo'"
  alias cdnginx="cd '/c/develop/tools/nginx'"
  alias gitlog="git log --oneline"
  
  alias backup='backup.sh develop project editplus react hyper-v python linux'
  alias restore='restore.sh develop project editplus react hyper-v python linux'

EOF

