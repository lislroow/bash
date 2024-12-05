#### docker login

- `~/.docker/config.json` 파일에 인증정보 `echo -n "admin:password" | base64` 를 추가 (-n: newline 추가 하지 않음)

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
