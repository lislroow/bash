#### partition 수정

```
dnf install parted e2fsprogs lvm2 -y

rsync -avz /home/ /home_backup/

umount /home

# e2fsck -f /dev/mapper/rl-home
# resize2fs /dev/mapper/rl-home 3G
# lvreduce -L 3G /dev/mapper/rl-home

lvremove /dev/mapper/rl-home

lvcreate -L 3G -n home rl
mkfs.xfs /dev/mapper/rl-home

lvextend -l +100%FREE /dev/mapper/rl-root

# resize2fs /dev/mapper/rl-root
xfs_growfs /

# mount /home
mount /dev/mapper/rl-home /home

rsync -avz /home_backup/ /home/

vi /etc/fstab
```


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