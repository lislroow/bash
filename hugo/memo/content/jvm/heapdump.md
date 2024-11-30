#### 1. heapdump 생성

- `jps` PID 확인
- `jmap` 은 jdk 에 포함되어 있으며, jmap 실행 계정은 대상 PID 의 계정 권한을 확인해야 함

```shell
jps -l
jmap -dump:live,format=b,file=<파일경로> <PID>
```

#### 2. heapdump 분석

