#### 3. forward proxy test

##### 2) spring app 구성

- `script.sh --build` 을 build 수행 후 `script --run` 으로 docker 컨테이너 실행 

```shell
#!/bin/bash

# VAR
CURRDIR=$( pwd -P )
APPNAME=$(basename $CURRDIR)
DOCKER_REGISTRY="172.28.200.40:5000"
# //VAR

# usage
function USAGE {
  cat << EOF
- USAGE
Usage: ${0##*/} <option>
 --build         : 전체 빌드 
 --build-java    : maven 빌드 실행
 --build-docker  : docker 이미지 빌드 실행
 --run           : docker 실행

EOF
  exit 1
}
# //usage

# options
OPTIONS="h"
LONGOPTIONS="help,build,build-app,build-docker,run"
function SetOptions {
  opts=$( getopt --options $OPTIONS \
                 --longoptions $LONGOPTIONS \
                 -- $* )
  eval set -- $opts
  
  while true; do
    if [ -z $1 ]; then
      break
    fi
    case $1 in
      -h | --help) ;;
      --build)
        TASKS=('build-java' 'build-docker')
        ;;
      --build-java)
        TASKS=('build-java')
        ;;
      --build-docker)
        TASKS=('build-docker')
        ;;
      --run)
        TASKS=('run')
        ;;
      --)
        ;;
      *)
        params+=($1)
        ;;
    esac
    shift
  done
}
SetOptions $*
if [ $? -ne 0 ]; then
  USAGE
  exit 1
fi
# //options

# main
function main {
  for task in ${TASKS[*]}; do
    echo "task: $task"
    case "${task}" in
      build-java)
        mvn clean package
        
        if [ $? -ne 0 ]; then
          echo "build failed"
        else
          echo "successful build"
        fi
        ;;
      build-docker)
        docker build -t ${DOCKER_REGISTRY}/${APPNAME} .
        docker login ${DOCKER_REGISTRY} -u admin -p 1
        docker push ${DOCKER_REGISTRY}/${APPNAME}
        docker rmi ${DOCKER_REGISTRY}/${APPNAME}
        ;;
      run)
        docker pull ${DOCKER_REGISTRY}/${APPNAME}
        ID=$(docker ps -a --filter "name=${APPNAME}" --format "{{.ID}}")
        if [ ! -z "${ID}" ]; then
          docker stop "${APPNAME}"
          docker rm "${ID}"
        fi
        docker run -itd \
          -e JAVA_OPTS="-Dspring.profiles.active=prod -Xms256m -Xmx256m -XX:MetaspaceSize=192m -XX:MaxMetaspaceSize=192m" \
          --network=host \
          --name=${APPNAME} \
          ${DOCKER_REGISTRY}/${APPNAME}
        ;;
    esac
  done
}
main
# //main

exit 0
```


##### 1) nginx 설정

```shell
$ apt-get install nginx

$ cat << EOF > /etc/nginx/sites-available/egress-proxy.conf
server {
  listen   15200;
  server_name  localhost;
  
  location / {
    proxy_pass http://172.28.200.1:8083;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
  }
}
EOF

$ ln -s /etc/nginx/sites-available/egress-proxy.conf /etc/nginx/sites-enabled/egress-proxy.conf

$ systemctl restart nginx
```

#### 2. sample app test

##### 3) scripts

```shell
cnameList=($(docker ps --format "{{.Names}}"))
midx=1
mtot=${#cnameList[*]}
for cname in ${cnameList[*]}; do
  cpid=($(docker inspect --format '{{.State.Pid}}' ${cname}))
  cport=$(netstat -ntpl | grep ${cpid} | awk '{ gsub(":::", "", $4); print $4 }')
  if [[ -z "${cport}" ]]; then
    cport=$(docker inspect --format '{{.HostConfig.PortBindings}}' ${cname})
  fi
  ccmd=$(docker inspect --format '{{.Config.Cmd}}' ${cname})
  if [[ -n "${cport}" ]] || [[ "${ccmd}" != "null" ]]; then
    echo "# [${midx}/${mtot}] ${cname}"
    echo "  - pid: ${cpid}"
    echo "  - listen port: ${cport}"
    echo "  - command: ${ccmd}"
  fi
  let "midx = midx + 1"
done
```

##### 2) docker build

- `Dockerfile` 설정

```docker
cat << EOF > images/java-app/Dockerfile
FROM localhost:5000/amazoncorretto:8-alpine-jdk-with-curl
WORKDIR /service
COPY ./target/*.jar /service
ENTRYPOINT ["/bin/sh", "-c", "java \${JAVA_OPTS} -jar *.jar"]
EOF
```

- docker build

```shell
BASEPATH="images"
APPNAME="java-app"
REGISTRY="localhost:5000"

docker build -t ${REGISTRY}/${APPNAME} ${BASEPATH}/${APPNAME}
docker image list
docker login ${REGISTRY} -u admin -p 1
docker push ${REGISTRY}/${APPNAME}
docker rmi ${REGISTRY}/${APPNAME}
```

- docker run

```shell
APPNAME="java-app"
REGISTRY="localhost:5000"

docker pull ${REGISTRY}/${APPNAME}
ID=$(docker ps -a --filter "name=java-app" --format "{{.ID}}")
if [ ! -z "${ID}" ]; then
  docker stop "java-app"
  docker rm "${ID}"
fi
docker run -itd -e JAVA_OPTS="-Xms256g -Xmx256g -XX:MetaspaceSize=192M -XX:MaxMetaspaceSize=192M" --network=host --name=${APPNAME} ${REGISTRY}/${APPNAME}
#docker run -itd -p 8080:8080 --name=${APPNAME} ${REGISTRY}/${APPNAME}
```

##### 1) java build

- java, maven 설치

```shell
apt-get install maven
apt-get install openjdk-8-jdk
update-alternatives --set java /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java
#update-alternatives --set java /usr/lib/jvm/java-11-openjdk-amd64/bin/java
JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/jre
```

- maven 프로젝트 소스 생성

```xml
mkdir -p images/java-app
cat << EOF > images/java-app/pom.xml
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>
  <groupId>mgkim</groupId>
  <artifactId>java-app</artifactId>
  <version>0.1</version>
  
  <properties>
    <java.version>8</java.version>
    <maven.compiler.target>8</maven.compiler.target>
    <maven.compiler.source>8</maven.compiler.source>
  </properties>
  
  <dependencyManagement>
    <dependencies>
      <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-dependencies</artifactId>
        <version>2.7.18</version>
        <type>pom</type>
        <scope>import</scope>
      </dependency>
    </dependencies>
  </dependencyManagement>
  
  <dependencies>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-actuator</artifactId>
    </dependency>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-web</artifactId>
    </dependency>
  </dependencies>
  
  <build>
    <defaultGoal>compile</defaultGoal>
    <plugins>
      <plugin>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-maven-plugin</artifactId>
        <version>2.7.18</version>
        <executions>
          <execution>
            <id>default-package</id>
            <phase>package</phase>
            <goals>
              <goal>repackage</goal>
            </goals>
          </execution>
        </executions>
      </plugin>
    </plugins>
  </build>
</project>
EOF
```

```java
mkdir -p images/java-app/src/main/java
cat << EOF > images/java-app/src/main/java/MainApplication.java
package app;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class MainApplication {
  public static void main(String[] args) {
    SpringApplication.run(MainApplication.class, args);
  }
}
EOF
```

- maven 빌드 및 java 실행

```shell
mvn package -f images/java-app/pom.xml
java -jar images/java-app/target/java-app*.jar
```


#### 1. docker 환경 구성 (ubuntu22)

- 구성 편의를 위해 아래 규칙으로 작업
- 모든 프로세스는 root 계정으로 설정
- https 설정 최소화

##### 1) 'nexus' 구성

- 파일: /opt/docker-compose/nexus.yml

```
services:
  nexus:
    image: sonatype/nexus3:latest
    container_name: nexus
    ports:
      - 9100:8081
    restart: always
    user: "root:root"
    volumes:
      - nexus_data:/nexus-data
```

- admin 계정 로그인
  `docker exec nexus bash -c 'cat /nexus-data/admin.password'`
- repositories 'docker-hosted' 생성
  `http: 5000 (입력)`, `Enable Docker V1 API (체크)`
- realms 'Docker Bearer Token Realm' 추가
- daemon.json 항목 추가
  - docker 이미지를 생성할 때 dns lookup 을 할 수 있도록 설정 추가
```
cat << EOF > /etc/docker/daemon.json
{
  "insecure-registries": ["localhost:5000"],
  "dns": ["8.8.8.8", "8.8.4.4"]
}
EOF
```
- systemctl restart docker
- docker login http://localhost:5000

##### 2) docker 이미지 push

- jdk 이미지 생성

```shell
mkdir -p images/jdk
cat << EOF > images/jdk/Dockerfile
FROM amazoncorretto:8-alpine-jdk
RUN apk --no-cache add curl
EOF

APPNAME="amazoncorretto:8-alpine-jdk-with-curl"
REGISTRY="localhost:5000"

docker build -t ${REGISTRY}/${APPNAME} images/jdk
docker image list
docker login ${REGISTRY} -u admin -p 1
docker push ${REGISTRY}/${APPNAME}
docker rmi ${REGISTRY}/${APPNAME}
```

- java-app(java application) 이미지 생성

```shell
mkdir -p images/java-app
cat << EOF > images/java-app/Dockerfile
FROM localhost:5000/amazoncorretto:8-alpine-jdk-with-curl
ENTRYPOINT ["/bin/sh", "-c", "which curl"]
EOF

APPNAME="java-app"
REGISTRY="localhost:5000"

docker build -t ${REGISTRY}/${APPNAME} images/java-app
docker image list
docker login ${REGISTRY} -u admin -p 1
docker push ${REGISTRY}/${APPNAME}
docker rmi ${REGISTRY}/${APPNAME}
```

##### 3) java-app 컨테이너 실행

```shell
APPNAME="java-app"

docker pull ${REGISTRY}/${APPNAME}
docker run -itd --network=host --name=${APPNAME} ${REGISTRY}/${APPNAME}

# 컨테이너 명령어
docker stop $container_name
docker kill $container_name
docker rm $container_name
docker logs $container_name
docker logs -f $container_name
docker logs --tail 50 $container_name
docker logs -t $container_name
```

#### docker 설치 (ubuntu22)

```shell
apt-get install apt-transport-https ca-certificates curl gnupg-agent software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update
apt-get install docker-ce docker-ce-cli containerd.io
```

#### locale

```shell
apt install locales
vi /etc/locale.gen
locale-gen 
locale -a
cat /etc/default/locale
cat << EOF > /etc/default/locale
LANG=ko_KR.utf8
EOF
timedatectl set-timezone Asia/Seoul
timedatectl
```

#### ufw: 방화벽

```shell
systemctl disable --now ufw
```

#### network

파일: /etc/netplan/00-installer-config.yaml

```yml
network:
  ethernets:
    eth0:
      addresses:
      - 172.28.200.40/24
      nameservers:
        addresses:
        - 8.8.8.8
        search: []
      routes:
      - to: default
        via: 172.28.200.1
  version: 2
```

