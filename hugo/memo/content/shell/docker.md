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

```shell
docker run -it --rm --name certbot -p 80:80 \
    -v "/etc/letsencrypt:/etc/letsencrypt" \
    -v "/lib/letsencrypt:/var/lib/letsencrypt" \
    certbot/certbot certonly --standalone -d 'nexus.mgkim.net'

---
Saving debug log to /var/log/letsencrypt/letsencrypt.log
Requesting a certificate for nexus.mgkim.net

Successfully received certificate.
Certificate is saved at: /etc/letsencrypt/live/nexus.mgkim.net/fullchain.pem
Key is saved at:         /etc/letsencrypt/live/nexus.mgkim.net/privkey.pem
This certificate expires on 2025-03-04.
These files will be updated when the certificate renews.
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
