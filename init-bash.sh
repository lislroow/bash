#!/bin/bash

BASHDIR=$( cd "$( dirname "$0" )" && pwd -P )

cat << EOF > ~/.bash_profile
#!/bin/bash

set -o vi

export LANG=ko_KR.utf8

export JAVA8="/c/develop/tools/corretto/corretto-8"
export JAVA11="/c/develop/tools/corretto/corretto-11"
export JAVA17="/c/develop/tools/corretto/corretto-17"
export JAVA21="/c/develop/tools/corretto/corretto-21"
export JAVA_HOME="\$JAVA17"
PATH="\$JAVA_HOME/bin:\$PATH"

#export MAVEN_HOME="/c/develop/tools/maven/maven-3.9.3"
export MAVEN_HOME="/c/develop/tools/maven/maven-3.9.11"
PATH="\$MAVEN_HOME/bin:\$PATH"

export GRADLE_HOME="/c/develop/tools/gradle/gradle-8.9"
PATH="\$GRADLE_HOME/bin:\$PATH"

export SPRING23="/c/develop/tools/spring/spring-2.3.8.RELEASE"
export SPRING27="/c/develop/tools/spring/spring-2.7.18"
export SPRING3="/c/develop/tools/spring/spring-3.4.0"
PATH="\$SPRING3/bin:\$PATH"

export PYTHON_HOME="/c/develop/tools/python"
PATH="\$PYTHON_HOME:\$PATH"
PATH="\$PYTHON_HOME/Scripts:\$PATH"

PATH="$BASHDIR:\$PATH"
PATH="$BASHDIR/bin:\$PATH"
PATH="$BASHDIR/bin/bcomp:\$PATH"
PATH="$BASHDIR/hugo/bin:\$PATH"
PATH="$BASHDIR/backup:\$PATH"
PATH="$BASHDIR/docker:\$PATH"
PATH="$BASHDIR/build:\$PATH"
PATH="$BASHDIR/docker/kafka-connector:\$PATH"
PATH="$BASHDIR/nginx:/c/develop/tools/nginx:\$PATH"
PATH="/c/Program Files/7-Zip:\$PATH"
PATH="/c/develop/tools/node/node-v25.2.1:\$PATH"
export PATH

alias curl="curl -s"
alias cdbash="cd '$BASHDIR'"
alias cdtemp="cd /c/temp"
alias cddocker="cd '$BASHDIR'/docker"
alias cdweb="cd '/c/project/react'"
alias cdmemo="cd '/c/bash/hugo/memo'"
alias cdnginx="cd '/c/develop/tools/nginx'"
alias cdscouter="cd '/c/develop/tools/scouter/scouter.server'"
alias cdproject="cd '/c/bash/hugo/project'"
alias gitlog="git log --oneline"

alias backup='backup.sh develop project editplus react hyper-v python linux'
alias restore='restore.sh develop project editplus react hyper-v python linux'

alias docker-ps='docker ps --format "table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}\t{{.Names}}"'

#source "${HOME}/.sdkman/bin/sdkman-init.sh"

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
  alias cdbash="cd /c/temp"
  alias cddocker="cd '$BASHDIR'/docker"
  alias cdweb="cd '/c/project/react'"
  alias cdmemo="cd '/c/linux/hugo/memo'"
  alias cdnginx="cd '/c/develop/tools/nginx'"
  alias cdscouter="cd '/c/develop/tools/scouter/scouter.server'"
  alias cdproject="cd '/c/project'"
  alias gitlog="git log --oneline"

  alias backup='backup.sh develop project editplus react hyper-v python linux'
  alias restore='restore.sh develop project editplus react hyper-v python linux'
  alias docker-ps='docker ps --format "table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}\t{{.Names}}"'

EOF

