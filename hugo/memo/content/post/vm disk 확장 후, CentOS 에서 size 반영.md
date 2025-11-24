---
title: "vm disk 확장 후, CentOS 에서 size 반영"
url: "/post/"
---
# `vm disk 확장 후, CentOS 에서 size 반영`


## 1. vm 에서 disk size 확장

### 1) disk `sda` 확인
- `lsblk` 명령은 disk, partition, LVM 을 확인할 수 있습니다.
- disk size 확장 전에는 disk `sda` 의 크기를 확인해야 합니다.
```shell
$ lsblk 
NAME                MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                   8:0    0   70G  0 disk  # (disk size 확장 전) '70G' 확인
├─sda1                8:1    0    1G  0 part /boot
└─sda2                8:2    0   69G  0 part 
  ├─cl_centos8-root 253:0    0 56.7G  0 lvm  /
  ├─cl_centos8-swap 253:1    0    7G  0 lvm  [SWAP]
  └─cl_centos8-home 253:2    0  5.3G  0 lvm  /home
sr0                  11:0    1 1024M  0 rom  
$
```

### 2) vm 에서 disk `sda` 에 size 확장
- CentOS 를 shutdown 하고, vm 에서 디스크 capacity 를 확장합니다. (70G > 80G 확장)
- CentOS 를 startup 하고, lsblk 로 disk `sda` 에 확장된 크기가 반영되었는지 확인합니다.
```shell
# sda 가 80G 로 확장된 것을 확인할 수 있습니다. (sda 는 disk 를 의미)
$ lsblk
NAME                MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                   8:0    0   80G  0 disk  # (disk size 확장 후) '70G' > '80G' 확인
├─sda1                8:1    0    1G  0 part /boot
└─sda2                8:2    0   69G  0 part 
  ├─cl_centos8-root 253:0    0 56.7G  0 lvm  /
  ├─cl_centos8-swap 253:1    0    7G  0 lvm  [SWAP]
  └─cl_centos8-home 253:2    0  5.3G  0 lvm  /home
sr0                  11:0    1 1024M  0 rom  
```

## 2. disk `sda` 에 미할당 공간을 partition `sda2` 에 확장
- `growpart` 명령으로 disk 의 미할당 공간을 partition 에 포함하도록 확장합니다.
- growpart 는 partition 자체를 확장하는 기능입니다.

### 1) growpart 실행 전 확인
```shell
$ lsblk 
NAME                MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                   8:0    0   80G  0 disk 
├─sda1                8:1    0    1G  0 part /boot
└─sda2                8:2    0   69G  0 part # (growpart 실행 전) '69G' 확인
  ├─cl_centos8-root 253:0    0 56.7G  0 lvm  /
  ├─cl_centos8-swap 253:1    0    7G  0 lvm  [SWAP]
  └─cl_centos8-home 253:2    0  5.3G  0 lvm  /home
sr0                  11:0    1 1024M  0 rom  

# volume group 확인
$ vgdisplay 
  --- Volume group ---
  VG Name               cl_centos8
  System ID             
  Format                lvm2
  Metadata Areas        1
  Metadata Sequence No  4
  VG Access             read/write
  VG Status             resizable
  MAX LV                0
  Cur LV                3
  Open LV               3
  Max PV                0
  Cur PV                1
  Act PV                1
  VG Size               <69.00 GiB
  PE Size               4.00 MiB
  Total PE              17663
  Alloc PE / Size       17663 / <69.00 GiB
  Free  PE / Size       0 / 0   # (growpart 실행 전) '0 / 0' 확인
  VG UUID               tJ9xgp-NhNP-7kPQ-JwKe-y1TQ-8jkP-1U5ox4

```

### 2) growpart 실행
- growpart 실행으로 `sda` disk 의 2번째 partition 인 `sda2` 는 69G 에서 79G 로 확장됩니다.
- growpart 는 disk 의 할당되지 않은 공간을 특정 partition `sda2` 에 확장시키는 것을 합니다.
- growpart 는 `cloud-utils-growpart` 패키지에 있습니다.
```shell
$ growpart /dev/sda 2
CHANGED: partition=2 start=2099200 old: size=144701440 end=146800640 new: size=165672927 end=167772127
```

### 3) growpart 실행 후 확인
- lsblk 에서 partition `sda2` size 가 79G 로 확장된 것을 볼 수 있습니다.
```shell
$ lsblk 
NAME                MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                   8:0    0   80G  0 disk 
├─sda1                8:1    0    1G  0 part /boot
└─sda2                8:2    0   79G  0 part # (growpart 실행 후) '69G' > '79G' 확인
  ├─cl_centos8-root 253:0    0 56.7G  0 lvm  /
  ├─cl_centos8-swap 253:1    0    7G  0 lvm  [SWAP]
  └─cl_centos8-home 253:2    0  5.3G  0 lvm  /home
sr0                  11:0    1 1024M  0 rom  

# volume group 확인
$ vgdisplay 
  --- Volume group ---
  VG Name               cl_centos8
  System ID             
  Format                lvm2
  Metadata Areas        1
  Metadata Sequence No  4
  VG Access             read/write
  VG Status             resizable
  MAX LV                0
  Cur LV                3
  Open LV               3
  Max PV                0
  Cur PV                1
  Act PV                1
  VG Size               <69.00 GiB
  PE Size               4.00 MiB
  Total PE              17663
  Alloc PE / Size       17663 / <69.00 GiB
  Free  PE / Size       0 / 0   # (growpart 실행 후) '0 / 0' 확인: resize 실행 후 변경 됨
  VG UUID               tJ9xgp-NhNP-7kPQ-JwKe-y1TQ-8jkP-1U5ox4
```

## 3. partition `sda2` 의 LVM `cl_centos8-root` 에 대해 `PV` size 확장
- partition `sda2` 에 속해있는 LVM `cl_centos8-root` 에 사용 가능한 `PV` size 를 확장 합니다.
- growpart 이후 사용하는 `pvresize` 은 LVM 전용 명령어 입니다.

### 1) pvresize 실행
```shell
$ pvresize /dev/sda2
  Physical volume "/dev/sda2" changed
  1 physical volume(s) resized or updated / 0 physical volume(s) not resized

$ vgdisplay
  --- Volume group ---
  VG Name               cl_centos8
  System ID             
  Format                lvm2
  Metadata Areas        1
  Metadata Sequence No  5
  VG Access             read/write
  VG Status             resizable
  MAX LV                0
  Cur LV                3
  Open LV               3
  Max PV                0
  Cur PV                1
  Act PV                1
  VG Size               <79.00 GiB
  PE Size               4.00 MiB
  Total PE              20223
  Alloc PE / Size       17663 / <69.00 GiB
  Free  PE / Size       2560 / 10.00 GiB   # (resize 실행 후) '0 / 0' > '2560 / 10.00 GiB' 확인
  VG UUID               tJ9xgp-NhNP-7kPQ-JwKe-y1TQ-8jkP-1U5ox4
$ 
```

### 2) pvresize 실행 후 확인
```shell
$ df -h
Filesystem                   Size  Used Avail Use% Mounted on
devtmpfs                     3.8G     0  3.8G   0% /dev
tmpfs                        3.8G     0  3.8G   0% /dev/shm
tmpfs                        3.8G  9.5M  3.8G   1% /run
tmpfs                        3.8G     0  3.8G   0% /sys/fs/cgroup
/dev/mapper/cl_centos8-root   57G   43G   15G  75% /  # (변경 전) '57G' 확인
/dev/sda1                   1014M  378M  637M  38% /boot
/dev/mapper/cl_centos8-home  5.4G  372M  5.0G   7% /home
//172.28.200.1/share         345G  234G  112G  68% /share
tmpfs                        775M     0  775M   0% /run/user/0

$ lvdisplay 
  --- Logical volume ---
  LV Path                /dev/cl_centos8/root
  LV Name                root
  VG Name                cl_centos8
  LV UUID                DzRXf6-roJe-0He9-MBow-ccu0-bWjk-qPxfZS
  LV Write Access        read/write
  LV Creation host, time centos8, 2021-11-28 12:38:35 +0900
  LV Status              available
  # open                 1
  LV Size                <56.66 GiB  # (변경 전) 56.66 GiB 확인
  Current LE             14504
  Segments               1
  Allocation             inherit
  Read ahead sectors     auto
  - currently set to     8192
  Block device           253:0
  ...
```

## 4. PV size 가 확장된 LVM `cl_centos8-root` 에 대해 `LV` size 확장
### 1) lvextend 실행
- pvresize 이후 사용하는 `lvextend` 는 LV size 를 확장합니다.
```shell
$ lvextend -r -l +100%FREE /dev/cl_centos8/root
  Size of logical volume cl_centos8/root changed from <56.66 GiB (14504 extents) to <66.66 GiB (17064 extents).
  Logical volume cl_centos8/root successfully resized.
meta-data=/dev/mapper/cl_centos8-root isize=512    agcount=4, agsize=3713024 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=1, sparse=1, rmapbt=0
         =                       reflink=1
data     =                       bsize=4096   blocks=14852096, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0, ftype=1
log      =internal log           bsize=4096   blocks=7252, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0
data blocks changed from 14852096 to 17473536

$ df -h
Filesystem                   Size  Used Avail Use% Mounted on
devtmpfs                     3.8G     0  3.8G   0% /dev
tmpfs                        3.8G     0  3.8G   0% /dev/shm
tmpfs                        3.8G  9.5M  3.8G   1% /run
tmpfs                        3.8G     0  3.8G   0% /sys/fs/cgroup
/dev/mapper/cl_centos8-root   67G   43G   25G  64% /  # (변경 후) 57G > 67G 확인
/dev/sda1                   1014M  378M  637M  38% /boot
/dev/mapper/cl_centos8-home  5.4G  372M  5.0G   7% /home
//172.28.200.1/share         345G  234G  112G  68% /share
tmpfs                        775M     0  775M   0% /run/user/0

$ lvdisplay 
  --- Logical volume ---
  LV Path                /dev/cl_centos8/root
  LV Name                root
  VG Name                cl_centos8
  LV UUID                DzRXf6-roJe-0He9-MBow-ccu0-bWjk-qPxfZS
  LV Write Access        read/write
  LV Creation host, time centos8, 2021-11-28 12:38:35 +0900
  LV Status              available
  # open                 1
  LV Size                <66.66 GiB  # (변경 후) 56.66 GiB > 66.66 GiB 변경 확인
  Current LE             17064
  Segments               2
  Allocation             inherit
  Read ahead sectors     auto
  - currently set to     8192
  Block device           253:0
  ...
```
