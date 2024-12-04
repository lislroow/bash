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
