#### postgres: /docker-entrypoint-initdb.d

- /docker-entrypoint-initdb.d 디렉토리에 sh, sql 파일이 있으면 스크립트를 실행

```yml
    volumes:
      - postgresql_data:/var/lib/postgresql/data
      - ./postgresql:/docker-entrypoint-initdb.d
```
