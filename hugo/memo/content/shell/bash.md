#### ssh 파일 전송

```
tar cvfz - N305.sh \
>  | ssh root@172.28.200.2 'tar zxvf - -C /root/bin'
```


#### getopts

- getopts는 옵션을 하나씩 처리할 때마다 옵션 문자를 OPTIND와 같은 변수에 저장하고, 각 옵션에 대한 인수는 $OPTARG에 저장됩니다.
- $OPTARG는 현재 옵션의 인수를 나타내며, 이 값은 getopts 명령어에서 옵션을 읽을 때 자동으로 설정됩니다.
- getopts는 옵션을 처리한 후, 아직 처리되지 않은 인수들을 남겨두는데, OPTIND는 다음 처리할 인수의 인덱스를 나타냅니다.
- shift $((OPTIND - 1))는 getopts로 처리한 옵션들을 제외한 나머지 인수들을 다룰 수 있도록, OPTIND - 1만큼 인수 목록을 왼쪽으로 이동시킵니다.

```shell
usage() {
  cat <<EOF
Usage: $0 [-h] <-f 파일 이름> <-o 출력 옵션> <prefix>

Options
  -f 파일 이름
  -o 출력 옵션

EOF
}

while getopts "f:o:" opt; do
  case "$opt" in
    f) echo "파일 이름: $OPTARG" ;;  # -f 뒤에 인수
    o) echo "출력 옵션: $OPTARG" ;;  # -o 뒤에 인수
    *) echo "지원되지 않는 옵션" ;;
  esac
  
  shift $((OPTIND - 1))
done

prefix=$1
```


#### 실행파일 PATH 에 있는지 확인

```shell
if ! which docker 1> /dev/null; then
  echo "docker not exist"
else
  echo "docker exist!"
fi
```