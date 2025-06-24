#### docker ENTRYPOINT

```
ENTRYPOINT ["/bin/bash", "-c", "pwd && ls -al && /app/start-scouter.sh"]
```

```
/app
total 36
drwxr-xr-x    1 root     root            18 Dec 11 07:53 .
drwxr-xr-x    1 root     root            17 Dec 11 07:53 ..
drwxr-xr-x    2 root     root           116 Dec 10 22:33 conf
drwxr-xr-x   17 root     root          4096 Dec 11 07:42 data
drwxr-xr-x    2 root     root            24 Dec  9 21:20 extweb
drwxr-xr-x    2 root     root          8192 Dec 10 22:33 lib
drwxr-xr-x    2 root     root          4096 Dec  9 21:20 plugin
-rw-r--r--    1 root     root          5936 Dec  9 21:20 scouter-server-boot.jar
-rwxr-xr-x    1 root     root           507 Dec 11 07:48 start-scouter.sh
-rwxr-xr-x    1 root     root            90 Dec 11 07:48 stop-scouter.sh
/bin/bash: line 1: /app/start-scouter.sh: cannot execute: required file not found
```

```
$ file start-scouter.sh 
start-scouter.sh: Bourne-Again shell script, ASCII text executable, with CRLF line terminators

$ dos2unix start-scouter.sh
dos2unix: converting file start-scouter.sh to Unix format...

$ file start-scouter.sh 
start-scouter.sh: Bourne-Again shell script, ASCII text executable
```

```
docker run --rm -it scouter-image /bin/bash \
cd /app \
./start-scouter.sh
```


#### docker search

```shell
$ docker search gitlab/gitlab-runner
NAME                                     DESCRIPTION                                     STARS     OFFICIAL
gitlab/gitlab-runner                     GitLab CI Multi Runner used to fetch and run…   957

$ curl -s https://registry.hub.docker.com/v2/repositories/gitlab/gitlab-runner/tags | grep '"name"'
```

#### docker login

- `~/.docker/config.json` 파일에 인증정보 `echo -n "admin:password" | base64` 를 추가 (-n: newline 추가 하지 않음)
- [중요] nexus 가 docker 로 실행 중일 경우 /etc/hosts 에 nexus 르 추가할 것. dns(8.8.8.8) 에서 nexus 를 찾지 못함

```json
{
  "auths": {
    "docker.mgkim.net:5000": {
      "auth": "YWRtaW46cGFzc3dvcmQ="  // base64(username:password)
    }
  }
}
```

#### lets encrypt

- ~/bin/letsencrypt.sh

```shell
#!/bin/bash

echo '[1/4] Set domain'
read -p "Enter the x (x.mgkim.net) : " -ei "x" domain
printf $'\n'$'\n'

echo '[2/4] Shutdown nginx (http:80)'
docker stop nginx
printf $'\n'$'\n'

echo '[3/4] Generate cert'
docker run -it --rm --name certbot -p 80:80 \
    -v "/etc/letsencrypt:/etc/letsencrypt" \
    -v "/lib/letsencrypt:/var/lib/letsencrypt" \
    certbot/certbot certonly --standalone -d "${domain}.mgkim.net"
printf $'\n'$'\n'

echo '[4/4] start nginx'
docker start nginx
printf $'\n'$'\n'

echo 'finish'
```


#### postgres /docker-entrypoint-initdb.d

- /docker-entrypoint-initdb.d 디렉토리에 sh, sql 파일이 있으면 스크립트를 실행

```yml
    volumes:
      - postgresql_data:/var/lib/postgresql/data
      - ./postgresql:/docker-entrypoint-initdb.d
```

```shell
# /docker-entrypoint-initdb.d/01_create_database.sh

USER_NAME=postgres

DATABASE_NAME=mattermost
psql -U $USER_NAME -tc "SELECT 1 FROM pg_database WHERE datname = '${DATABASE_NAME}'" | grep -q 1 \
  || psql -U $USER_NAME -c "CREATE DATABASE ${DATABASE_NAME}"

DATABASE_NAME=sonarqube
psql -U $USER_NAME -tc "SELECT 1 FROM pg_database WHERE datname = '${DATABASE_NAME}'" | grep -q 1 \
  || psql -U $USER_NAME -c "CREATE DATABASE ${DATABASE_NAME}"
```
