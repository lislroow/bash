#### 실행파일 PATH 에 있는지 확인

```shell
if ! which docker 1> /dev/null; then
  echo "docker not exist"
else
  echo "docker exist!"
fi
```
