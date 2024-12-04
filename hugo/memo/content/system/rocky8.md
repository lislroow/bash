#### dnf

```
dnf history

# 패키지 정보 확인
dnf check-update

# 시스템 패키지 업데이트
dnf update -y

# 모든 패키지 업그레이드 및 의존성 해결
dnf upgrade --refresh -y

# 시스템 전반적인 클린업
dnf autoremove -y
dnf clean all

# 커널 업데이트
dnf install kernel
```