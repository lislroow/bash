# `oracle`

## 1. Oracle 12c 설치

### 1) 시스템 계정 준비
```shell
groupadd oinstall
groupadd dba
useradd -g oinstall -G dba oracle
```

### 2) 설치 디렉토리 준비
```shell
mkdir -p /prod/oracle12/app
mkdir -p /prod/oracle12/oraInventory
chown -R oracle:oinstall /prod/oracle12/app
chown -R oracle:oinstall /prod/oracle12/oraInventory
chmod -R 775 /prod/oracle12/app
chmod -R 775 /prod/oracle12/oraInventory
chmod g+s /prod/oracle12/app
chmod g+s /prod/oracle12/oraInventory
```

### 3) 시스템 변수
```shell
export TMPDIR=$TMP
export ORACLE_BASE=/prod/oracle12/app/
export ORACLE_HOME=$ORACLE_BASE/product/12.2.0/dbhome_1
export ORACLE_HOME_LISTNER=$ORACLE_HOME/bin/lsnrctl
export ORACLE_SID=orcl
export LD_LIBRARY_PATH=/lib:/usr/lib:/usr/lib64:$ORACLE_HOME/lib
export CLASSPATH=$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib
export PATH=$ORACLE_HOME/bin:$PATH:$HOME/.local/bin:$HOME/bin
```

### 4) gui 패키지 설치 (runInstaller 방식)
```shell
$ yum grouplist
사용 가능한 환경 그룹 :
   서버 - GUI 사용
   최소 설치
   워크스테이션
   가상화 호스트
   사용자 정의 운영 체제
$ yum groupinstall "서버 - GUI 사용"
```
- 설치 후 runlevel 변경: `$ systemctl set-default graphical.target`

### 5) Oracle 12c EE 설치
- gui 환경으로 booting 후 oracle 계정으로 로그인하고 `runInstaller` 실행
- 설치 파일: `oracle-ee_12102_linux_x64_1of2.zip`, `oracle-ee_12102_linux_x64_2of2.zip`


### 6) systemctl 등록
- systemctl 환경변수 파일: /etc/sysconfig/ora12c.env
- 소유자(oracle) 설정: `chown oracle:db /etc/sysconfig/ora12c.env`

```shell
ORACLE_BASE=/prod/oracle12/app
ORACLE_HOME=$ORACLE_BASE/product/12.2.0/dbhome_1
ORACLE_SID=ora12c
```

### 7) 각종 오류
- ORA-01102: cannot mount database in EXCLUSIVE mode
```
cat $ORACLE_BASE/admin/ora12c/pfile/init.ora.1028202115570
cp $ORACLE_BASE/admin/ora12c/pfile/init.ora.1028202115570 $ORACLE_HOME/dbs/initora12c.ora
```

- ORA-01033: ORACLE initialization or shutdown in progress 
```
alter pluggable database pdborcl open read write;
```

- systemctl service 파일 생성
- service 파일에는 환경변수 파일을 적용할 것
- `ora12c@lsnrctl.service`, `ora12c@dbms.service`

### 8) oratab 파일 
- 파일: /etc/oratab
```
ora12c:/prod/oracle12/app/product/12.2.0/dbhome_1:Y
```
- 소유자(oracle) 설정: `chown oracle:db /etc/oratab`


### 9) sysctl 설정
- 파일: /etc/sysctl.conf

```
fs.aio-max-nr = 1048576
fs.file-max = 6815744
kernel.shmall = 2097152
kernel.shmmax = 4056393728
kernel.shmmni = 4096
kernel.sem = 250 32000 100 128
net.ipv4.ip_local_port_range = 9000 65500
net.core.rmem_default = 262144
net.core.rmem_max = 4194304
net.core.wmem_default = 262144
net.core.wmem_max = 1048586
```
- 반영: `sysctl -p`
- 확인: `sysctl -a`

### 10) limits 설정
- 파일: /etc/security/limits.conf

```
oracle soft nproc 2047
oracle hard nproc 16384
oracle soft nofile 1024
oracle hard nofile 65536
```

### 11) max_string_size = EXTENDED

```
startup mount;
alter database open migrate;
select con_id, name, open_mode from v$pdbs;
alter session set container=PDB$SEED;
alter system set max_string_size=extended scope=spfile;
@?/rdbms/admin/utl32k.sql;
alter session set container=SPADBP;
alter pluggable database SPADBP open upgrade;
alter system set max_string_size=extended scope=spfile;
@?/rdbms/admin/utl32k.sql;
@?/rdbms/admin/utlrp.sql;
alter pluggable database SPADBP close immediate;
```

### 12) PDB 자동 시작

```
select con_id, name, open_mode from v$pdbs;
CREATE OR REPLACE TRIGGER open_pdbs 
  AFTER STARTUP ON DATABASE 
BEGIN 
  EXECUTE IMMEDIATE 'ALTER PLUGGABLE DATABASE ALL OPEN'; 
END open_pdbs;
/
commit;
```


## 2. Oracle 19c 설정
### 1) 환경 정보
```sql
# 설치 경로(디렉토리) 확인
# cat /etc/oratab
ORCLCDB:/opt/oracle/product/19c/dbhome_1:Y

# 서비스명 확인
# systemctl list-units | grep oracle
$ oracledb_ORCLCDB-19c.service  loaded active running   SYSV: This script is responsible for taking care of configuring the Oracle Database and its associated services.

# 서비스 실행 확인
# systemctl status oracledb_ORCLCDB-19c
/etc/rc.d/init.d/oracledb_ORCLCDB-19c

# lsnrctl status | grep -n Service
# listener 에 등록된 서비스명 확인 (ORCLCDB)
22:Services Summary...
23:Service "1db7b95ef20a357be0633cc81cac0df1" has 1 instance(s).
25:Service "1db9133561fa1204e0633cc81cac10e9" has 1 instance(s).
27:Service "ORCLCDB" has 2 instance(s).
30:Service "ORCLCDBXDB" has 1 instance(s).
34:Service "orclpdb1" has 1 instance(s).

# ORCLCDB 에 접속
# sqlplus system/passwd@localhost:1521/ORCLCDB

# 인스턴스 확인 (OPEN 이 되어야 함)
SQL> select status from v$instance;

STATUS
------------
OPEN

# CDB 여부 확인
SQL> select name, cdb from v$database;

NAME    CDB
--------- ---
ORCLCDB   YES

SQL> 

# pdb 확인
SQL> select con_id, name, open_mode from v$pdbs;

  CON_ID NAME                                 OPEN_MODE
---------- -------------------------------------------------
   2 PDB$SEED                                 READ ONLY
   3 ORCLPDB1                                 READ WRITE

# 클라이언트에서 rocky8-oracle19:1521/orclpdb1 접속
orclpdb1 =
  (DESCRIPTION =
    (ADDRESS =(PROTOCOL=TCP)(HOST=172.28.200.51)(PORT=1521)
  )
  (CONNECT_DATA =(SERVICE_NAME=orclpdb1)
  )
)
```


### 2) 새로운 pdb 생성 및 계정 생성
#### 2.1) pdb 생성
```sql
# 접속
$ sqlplus sys as sysdba

# 데이터베이스 상태 확인
SQL> SELECT STATUS FROM V$INSTANCE;

# 현재 세션을 CDB 로 변경하고, 변경 여부 확인
SQL> ALTER SESSION SET CONTAINER = CDB$ROOT;
SQL> SHOW CON_NAME;

# pdb 생성
SQL> CREATE PLUGGABLE DATABASE market ADMIN USER pdb_market IDENTIFIED BY 1 FILE_NAME_CONVERT = ('/opt/oracle/oradata/ORCLCDB', '/opt/oracle/oradata/ORCLCDB/market');
SQL> CREATE PLUGGABLE DATABASE develop ADMIN USER pdb_develop IDENTIFIED BY 1 FILE_NAME_CONVERT = ('/opt/oracle/oradata/ORCLCDB', '/opt/oracle/oradata/ORCLCDB/develop');

Pluggable database created.

# 생성된 pdb 확인
SQL> SHOW PDBS;

    CON_ID CON_NAME       OPEN MODE  RESTRICTED
---------- ------------------------------ ---------- ----------
   2 PDB$SEED       READ ONLY  NO
   3 ORCLPDB1       READ WRITE NO
   4 MARKET         READ WRITE NO

# 생성된 pdb 시작(OPEN)
SQL> ALTER PLUGGABLE DATABASE market OPEN;
```

#### 2.2) 새로운 pdb 에 user 생성
```sql
# 현재 세션이 연결된 컨테이너 확인
SQL> SHOW CON_NAME;
CON_NAME
------------------------------
CDB$ROOT

# 현재 세션을 PDB 로 변경
SQL> ALTER SESSION SET CONTAINER = market;

Session altered.

# PDB 로 세션 변경이 되었는지 확인 
SQL> SHOW CON_NAME;

CON_NAME
------------------------------
MARKET

# 'ORA-65096: invalid common user or role name' 오류 발생
SQL> ALTER SESSION SET "_oracle_script"=true;
SQL> CREATE USER mkuser IDENTIFIED BY 1;

# GRANT RESOURCE TO mkuser (ORA-01924: role 'RESOURCE' not granted or does not exist)
SQL> GRANT CREATE SESSION TO mkuser;
SQL> GRANT CREATE TABLE TO mkuser;
SQL> GRANT CREATE VIEW TO mkuser;
SQL> GRANT CREATE PROCEDURE TO mkuser;
SQL> GRANT CREATE SEQUENCE TO mkuser;
SQL> GRANT CREATE TRIGGER TO mkuser;
SQL> GRANT CREATE SYNONYM TO mkuser;
SQL> GRANT CREATE TYPE TO mkuser;
SQL> GRANT UNLIMITED TABLESPACE TO mkuser;

# tnsnames.ora 추가 (sqlplus,imp,exp 사용시)
/opt/oracle/product/19c/dbhome_1/network/admin/tnsnames.ora
market =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = rocky8-oracle19c)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = market)
    )
  )

```


### 3) pdb 삭제

```sql
SQL> SHOW PDBS

    CON_ID CON_NAME       OPEN MODE  RESTRICTED
---------- ------------------------------ ---------- ----------
   2 PDB$SEED       READ ONLY  NO
   3 ORCLPDB1       READ WRITE NO
   4 MARKET         READ WRITE NO
   
# pdb close 상태로 전환
SQL> ALTER PLUGGABLE DATABASE market CLOSE IMMEDIATE;

Pluggable database altered.

# pdb unplug
SQL> ALTER PLUGGABLE DATABASE market UNPLUG INTO '/home/oracle/market.xml';

Pluggable database altered.

# pdb 상태 확인
SQL> SHOW PDBS;

    CON_ID CON_NAME       OPEN MODE  RESTRICTED
---------- ------------------------------ ---------- ----------
   2 PDB$SEED       READ ONLY  NO
   3 ORCLPDB1       READ WRITE NO
   4 MARKET         MOUNTED

# pdb 삭제
SQL> DROP PLUGGABLE DATABASE market INCLUDING DATAFILES;

Pluggable database dropped.

# pdb 상태 확인
SQL> SHOW PDBS;

    CON_ID CON_NAME       OPEN MODE  RESTRICTED
---------- ------------------------------ ---------- ----------
   2 PDB$SEED       READ ONLY  NO
   3 ORCLPDB1       READ WRITE NO
```

### 4) dump 파일 import 하기

imp 명령어와 impdp 명령어가 있으며, exp 로 생성한 dump 는 imp 로 import 해야 함

```shell
# dump 파일의 메타 정보 확인
$ imp system/passwd FILE=/opt/dump/fund.dmp LOG=dump_log.log SHOW=Y FULL=Y

# dump 파일의 캐릭터셋은 NLS_LANG 변수로 설정
$ export NLS_LANG=KOREAN_KOREA.KO16MSWIN949

# only schema import
$ imp system/passwd@develop FILE=/opt/dump/fund.dmp LOG=dump_log.log FROMUSER=FUNDO TOUSER=mkuser ROWS=N

# data import (ignore=Y 는 schema 가 있을 경우 무시하고 data 를 import)
$ imp system/passwd@develop FILE=/opt/dump/fund.dmp LOG=dump_log.log FROMUSER=FUNDO TOUSER=mkuser ROWS=Y IGNORE=Y

```

system 테이블스페이스에는 데이터를 import 할 수 없음 

```sql
# pdb 선택
SQL> ALTER SESSION SET CONTAINER = develop;

# 테이블스페이스 생성
SQL> CREATE TABLESPACE develop
  DATAFILE '/opt/oracle/oradata/ORCLCDB/develop/develop.dbf' 
  SIZE 10G 
  AUTOEXTEND ON 
  NEXT 50M MAXSIZE UNLIMITED;

# mkuser 기본 테이블스페이스 지정 및 할당량 지정
SQL> ALTER USER mkuser DEFAULT TABLESPACE develop;
SQL> ALTER USER mkuser QUOTA UNLIMITED ON develop;

---

# pdb 선택
SQL> ALTER SESSION SET CONTAINER = develop;

# mkuser 계정 삭제
SQL> ALTER SESSION SET "_oracle_script"=true;
SQL> DROP USER mkuser CASCADE;
# ORA-28014: cannot drop administrative user or role
SQL> SELECT * FROM dba_role_privs WHERE grantee = 'mkuser';
SQL> REVOKE SYSDBA FROM mkuser;
SQL> REVOKE DBA FROM mkuser;
# ORA-01940: cannot drop a user that is currently connected
SQL> SELECT SID,SERIAL# FROM V$SESSION WHERE USERNAME = 'MKUSER';
SQL> ALTER SYSTEM KILL SESSION 'SID,SERIAL#';

# 테이블스페이스 삭제 (dbf 파일은 삭제되지 않음)
SQL> DROP TABLESPACE develop;
SQL> DROP TABLESPACE develop INCLUDING CONTENTS AND DATAFILES;

# dbf 파일 삭제
$ rm -rf /opt/oracle/oradata/ORCLCDB/develop/develop.dbf

---

# mkuser 계정 생성 (기본 테이블스페이스 지정)
SQL> ALTER SESSION SET "_oracle_script"=true;
SQL> CREATE USER mkuser IDENTIFIED BY 1 DEFAULT TABLESPACE develop;
```


### 5) expdp 명령(pump)으로 dump 생성하기

```sql
# backup 디렉토리 설정
SQL> CREATE DIRECTORY backup_dir AS '/home/oracle';
SQL> GRANT READ, WRITE ON DIRECTORY backup_dir TO mkuser;

# expdp 명령 dump 생성
$ expdp mkuser/passwd@develop DIRECTORY=backup_dir DUMPFILE=develop.dmp LOGFILE=develop_backup.log

---

# impdp 명령 dump 적재 (for test)
# REMAP_SCHEMA=mkuser:testuser: 덤프 파일에 있는 데이터를 mkuser라는 원래 사용자로부터 testuser로 매핑하여 적재
$ impdp testuser/passwd@testdb DIRECTORY=backup_dir DUMPFILE=develop.dmp REMAP_SCHEMA=mkuser:testuser LOGFILE=import_log.log

# impdp 실행 전 디렉토리 생성
SQL> CREATE DIRECTORY backup_dir AS '/home/oracle';
SQL> GRANT READ, WRITE ON DIRECTORY backup_dir TO testuser;
```


### 6) 데이터 이관 작업

```sql
# 임시 테이블스페이스, 계정 생성

ALTER SESSION SET CONTAINER = develop;

CREATE TABLESPACE develop_test
  DATAFILE '/opt/oracle/oradata/ORCLCDB/develop/test.dbf' 
  SIZE 100M 
  AUTOEXTEND ON 
  NEXT 50M MAXSIZE UNLIMITED;

ALTER SESSION SET "_oracle_script"=true;
CREATE USER testuser IDENTIFIED BY 1 DEFAULT TABLESPACE develop_test;
ALTER USER testuser QUOTA UNLIMITED ON develop_test;
GRANT CREATE SESSION TO testuser;
GRANT CREATE TABLE TO testuser;
GRANT CREATE VIEW TO testuser;
GRANT CREATE PROCEDURE TO testuser;
GRANT CREATE SEQUENCE TO testuser;
GRANT CREATE TRIGGER TO testuser;
GRANT CREATE SYNONYM TO testuser;
GRANT CREATE TYPE TO testuser;
GRANT UNLIMITED TABLESPACE TO testuser;
GRANT READ, WRITE ON DIRECTORY backup_dir TO testuser;

---

# imp 실행
export NLS_LANG=KOREAN_KOREA.KO16MSWIN949
imp system/1 FILE=./backup.dmp LOG=dump_log.log SHOW=Y FULL=Y

imp system/passwd@develop FILE=./backup.dmp LOG=dump_log.log FROMUSER=OCRM TOUSER=testuser ROWS=N
imp system/passwd@develop FILE=./backup.dmp LOG=dump_log.log FROMUSER=OCRM TOUSER=testuser ROWS=Y IGNORE=Y

---

# (데이터 정리 후) expdp 실행
expdp testuser/passwd@develop DIRECTORY=backup_dir DUMPFILE=exp.dmp TABLES=tb_foo,tb_bar LOGFILE=backup_log.log

# impdp 실행
impdp mkuser/passwd@develop DIRECTORY=backup_dir DUMPFILE=exp.dmp REMAP_SCHEMA=testuser:mkuser REMAP_TABLESPACE=develop_test:develop LOGFILE=import_log.log

---

# 임시 테이블스페이스, 계정 삭제
DROP USER testuser cascade;
DROP TABLESPACE develop_test INCLUDING CONTENTS AND DATAFILES;
```


### 7) sqlldr 우편번호 적재
```shell
# 우편번호 데이터
$ curl -sOL https://www.epost.go.kr/search/areacd/zipcode_DB.zip
# 압축 해제 대상 디렉토리 지정, 파일명 인코딩 설정
$ unzip -O cp949 -d zipcode zipcode_DB.zip
# 파일명 인코딩 변경
#$ yum install -y convmv
#$ convmv -f cp949 -t utf-8 --notest ./zipcode/*

# ZIPCODE 테이블 생성
CREATE TABLE "MKUSER"."ZIPCODE" 
   (  "ZIPCODE" VARCHAR2(10) NOT NULL ENABLE, 
  "SIDO" VARCHAR2(50), 
  "SIDO_EN" VARCHAR2(100), 
  "SIGUNGU" VARCHAR2(50), 
  "SIGUNGU_EN" VARCHAR2(100), 
  "EUPMYUN" VARCHAR2(50), 
  "EUPMYUN_EN" VARCHAR2(100), 
  "ROAD_CD" VARCHAR2(20), 
  "ROAD_NM" VARCHAR2(100), 
  "ROAD_NM_EN" VARCHAR2(100), 
  "UNDERGROUND_YN" VARCHAR2(1), 
  "BLDG_NO1" VARCHAR2(10), 
  "BLDG_NO2" VARCHAR2(10), 
  "BLDG_MGMT_NO" VARCHAR2(50), 
  "LG_DELIVERY_NM" VARCHAR2(100), 
  "SIGUNGU_BLDG_NM" VARCHAR2(100), 
  "LEGAL_DONG_CD" VARCHAR2(20), 
  "LEGAL_DONG_NM" VARCHAR2(100), 
  "RI_NAME" VARCHAR2(100), 
  "ADMIN_DONG_NM" VARCHAR2(100), 
  "MOUNTAIN_YN" VARCHAR2(1), 
  "JIBEON_NO1" VARCHAR2(10), 
  "EUPMYUNDONG_SEQNO" VARCHAR2(10), 
  "JIBEON_NO2" VARCHAR2(10), 
  "OLD_ZIPCODE" VARCHAR2(10), 
  "ZIPCODE_SEQNO" VARCHAR2(10)
   );
COMMENT ON TABLE MKUSER.ZIPCODE IS '우편번호정보';
COMMENT ON COLUMN MKUSER.ZIPCODE.ZIPCODE IS '우편번호';
COMMENT ON COLUMN MKUSER.ZIPCODE.SIDO IS '시도';
COMMENT ON COLUMN MKUSER.ZIPCODE.SIDO_EN IS '시도영문';
COMMENT ON COLUMN MKUSER.ZIPCODE.SIGUNGU IS '시군구';
COMMENT ON COLUMN MKUSER.ZIPCODE.SIGUNGU_EN IS '시군구영문';
COMMENT ON COLUMN MKUSER.ZIPCODE.EUPMYUN IS '읍면';
COMMENT ON COLUMN MKUSER.ZIPCODE.EUPMYUN_EN IS '읍면영문';
COMMENT ON COLUMN MKUSER.ZIPCODE.ROAD_CD IS '도로명코드';
COMMENT ON COLUMN MKUSER.ZIPCODE.ROAD_NM IS '도로명';
COMMENT ON COLUMN MKUSER.ZIPCODE.ROAD_NM_EN IS '도로명영문';
COMMENT ON COLUMN MKUSER.ZIPCODE.UNDERGROUND_YN IS '지하여부';
COMMENT ON COLUMN MKUSER.ZIPCODE.BLDG_NO1 IS '건물번호본번';
COMMENT ON COLUMN MKUSER.ZIPCODE.BLDG_NO2 IS '건물번호부번';
COMMENT ON COLUMN MKUSER.ZIPCODE.BLDG_MGMT_NO IS '건물관리번호';
COMMENT ON COLUMN MKUSER.ZIPCODE.LG_DELIVERY_NM IS '다량배달처명';
COMMENT ON COLUMN MKUSER.ZIPCODE.SIGUNGU_BLDG_NM IS '시군구용건물명';
COMMENT ON COLUMN MKUSER.ZIPCODE.LEGAL_DONG_CD IS '법정동코드';
COMMENT ON COLUMN MKUSER.ZIPCODE.LEGAL_DONG_NM IS '법정동명';
COMMENT ON COLUMN MKUSER.ZIPCODE.RI_NAME IS '리명';
COMMENT ON COLUMN MKUSER.ZIPCODE.ADMIN_DONG_NM IS '행정동명';
COMMENT ON COLUMN MKUSER.ZIPCODE.MOUNTAIN_YN IS '산여부';
COMMENT ON COLUMN MKUSER.ZIPCODE.JIBEON_NO1 IS '지번본번';
COMMENT ON COLUMN MKUSER.ZIPCODE.EUPMYUNDONG_SEQNO IS '읍면동일련번호';
COMMENT ON COLUMN MKUSER.ZIPCODE.JIBEON_NO2 IS '지번부번';
COMMENT ON COLUMN MKUSER.ZIPCODE.OLD_ZIPCODE IS '구우편번호';
COMMENT ON COLUMN MKUSER.ZIPCODE.ZIPCODE_SEQNO IS '우편번호일련번호';


## import-zipcode.sh
#!/bin/bash

WORKDIR="zipcode"
ORACLEDB_USER="mkuser"
ORACLEDB_PASSWORD="1"
SERVICE_NAME="develop"
TABLE_NAME="ZIPCODE"

cat <<- EOF > ${WORKDIR}/${TABLE_NAME}.ddl
CREATE TABLE "MKUSER"."ZIPCODE" 
   (  "ZIPCODE" VARCHAR2(10) NOT NULL ENABLE, 
  "SIDO" VARCHAR2(50), 
  "SIDO_EN" VARCHAR2(100), 
  "SIGUNGU" VARCHAR2(50), 
  "SIGUNGU_EN" VARCHAR2(100), 
  "EUPMYUN" VARCHAR2(50), 
  "EUPMYUN_EN" VARCHAR2(100), 
  "ROAD_CD" VARCHAR2(20), 
  "ROAD_NM" VARCHAR2(100), 
  "ROAD_NM_EN" VARCHAR2(100), 
  "UNDERGROUND_YN" VARCHAR2(1), 
  "BLDG_NO1" VARCHAR2(10), 
  "BLDG_NO2" VARCHAR2(10), 
  "BLDG_MGMT_NO" VARCHAR2(50), 
  "LG_DELIVERY_NM" VARCHAR2(100), 
  "SIGUNGU_BLDG_NM" VARCHAR2(100), 
  "LEGAL_DONG_CD" VARCHAR2(20), 
  "LEGAL_DONG_NM" VARCHAR2(100), 
  "RI_NAME" VARCHAR2(100), 
  "ADMIN_DONG_NM" VARCHAR2(100), 
  "MOUNTAIN_YN" VARCHAR2(1), 
  "JIBEON_NO1" VARCHAR2(10), 
  "EUPMYUNDONG_SEQNO" VARCHAR2(10), 
  "JIBEON_NO2" VARCHAR2(10), 
  "OLD_ZIPCODE" VARCHAR2(10), 
  "ZIPCODE_SEQNO" VARCHAR2(10)
   );
COMMENT ON TABLE MKUSER.ZIPCODE IS '우편번호정보';
COMMENT ON COLUMN MKUSER.ZIPCODE.ZIPCODE IS '우편번호';
COMMENT ON COLUMN MKUSER.ZIPCODE.SIDO IS '시도';
COMMENT ON COLUMN MKUSER.ZIPCODE.SIDO_EN IS '시도영문';
COMMENT ON COLUMN MKUSER.ZIPCODE.SIGUNGU IS '시군구';
COMMENT ON COLUMN MKUSER.ZIPCODE.SIGUNGU_EN IS '시군구영문';
COMMENT ON COLUMN MKUSER.ZIPCODE.EUPMYUN IS '읍면';
COMMENT ON COLUMN MKUSER.ZIPCODE.EUPMYUN_EN IS '읍면영문';
COMMENT ON COLUMN MKUSER.ZIPCODE.ROAD_CD IS '도로명코드';
COMMENT ON COLUMN MKUSER.ZIPCODE.ROAD_NM IS '도로명';
COMMENT ON COLUMN MKUSER.ZIPCODE.ROAD_NM_EN IS '도로명영문';
COMMENT ON COLUMN MKUSER.ZIPCODE.UNDERGROUND_YN IS '지하여부';
COMMENT ON COLUMN MKUSER.ZIPCODE.BLDG_NO1 IS '건물번호본번';
COMMENT ON COLUMN MKUSER.ZIPCODE.BLDG_NO2 IS '건물번호부번';
COMMENT ON COLUMN MKUSER.ZIPCODE.BLDG_MGMT_NO IS '건물관리번호';
COMMENT ON COLUMN MKUSER.ZIPCODE.LG_DELIVERY_NM IS '다량배달처명';
COMMENT ON COLUMN MKUSER.ZIPCODE.SIGUNGU_BLDG_NM IS '시군구용건물명';
COMMENT ON COLUMN MKUSER.ZIPCODE.LEGAL_DONG_CD IS '법정동코드';
COMMENT ON COLUMN MKUSER.ZIPCODE.LEGAL_DONG_NM IS '법정동명';
COMMENT ON COLUMN MKUSER.ZIPCODE.RI_NAME IS '리명';
COMMENT ON COLUMN MKUSER.ZIPCODE.ADMIN_DONG_NM IS '행정동명';
COMMENT ON COLUMN MKUSER.ZIPCODE.MOUNTAIN_YN IS '산여부';
COMMENT ON COLUMN MKUSER.ZIPCODE.JIBEON_NO1 IS '지번본번';
COMMENT ON COLUMN MKUSER.ZIPCODE.EUPMYUNDONG_SEQNO IS '읍면동일련번호';
COMMENT ON COLUMN MKUSER.ZIPCODE.JIBEON_NO2 IS '지번부번';
COMMENT ON COLUMN MKUSER.ZIPCODE.OLD_ZIPCODE IS '구우편번호';
COMMENT ON COLUMN MKUSER.ZIPCODE.ZIPCODE_SEQNO IS '우편번호일련번호';
EOF


sqlplus \
  ${ORACLEDB_USER}/${ORACLEDB_PASSWORD}@${SERVICE_NAME} \
  @${WORKDIR}/${TABLE_NAME}.ddl

cat <<- EOF > ${WORKDIR}/${TABLE_NAME}.ctl
LOAD DATA
CHARACTERSET AL32UTF8
APPEND
INTO TABLE ${TABLE_NAME}
FIELDS TERMINATED BY '|' 
TRAILING NULLCOLS
(
    ZIPCODE CHAR,
    SIDO CHAR,
    SIDO_EN CHAR,
    SIGUNGU CHAR,
    SIGUNGU_EN CHAR,
    EUPMYUN CHAR,
    EUPMYUN_EN CHAR,
    ROAD_CD CHAR,
    ROAD_NM CHAR,
    ROAD_NM_EN CHAR,
    UNDERGROUND_YN CHAR,
    BLDG_NO1 CHAR,
    BLDG_NO2 CHAR,
    BLDG_MGMT_NO CHAR,
    LG_DELIVERY_NM CHAR,
    SIGUNGU_BLDG_NM CHAR,
    LEGAL_DONG_CD CHAR,
    LEGAL_DONG_NM CHAR,
    RI_NAME CHAR,
    ADMIN_DONG_NM CHAR,
    MOUNTAIN_YN CHAR,
    JIBEON_NO1 CHAR,
    EUPMYUNDONG_SEQNO CHAR,
    JIBEON_NO2 CHAR,
    OLD_ZIPCODE CHAR,
    ZIPCODE_SEQNO CHAR
)
EOF

for file in ${WORKDIR}/*.txt; do
  sqlldr \
    ${ORACLEDB_USER}/${ORACLEDB_PASSWORD}@${SERVICE_NAME} \
    data=$file \
    control=${WORKDIR}/${TABLE_NAME}.ctl \
    log=${WORKDIR}/debug.log \
    skip=1
done
```

### 8) pdb 관리자 계정 변경

새로운 관리자 계정 생성 후 기존 계정을 삭제해야 함

```sql
CREATE USER pdb_develop IDENTIFIED BY passwd;

-- 새로운 관리자 계정 권한 부여
GRANT DBA TO pdb_develop;
GRANT CREATE SESSION TO pdb_develop;
GRANT CREATE ANY TABLE TO pdb_develop;
GRANT UNLIMITED TABLESPACE TO pdb_develop;

-- 기존 관리자 계정 권한 회수 및 삭제
REVOKE DBA FROM pdb_market;
DROP USER pdb_market CASCADE;
```

### 9) pdb mkuser 백업

```shell
# (참고) 디렉토리 변경
SQL> CREATE DIRECTORY backup_dir AS '/home/oracle/dump';
SQL> DROP DIRECTORY backup_dir;
SQL> CREATE DIRECTORY backup_dir AS '/home/oracle';
SQL> GRANT READ, WRITE ON DIRECTORY backup_dir TO mkuser;

$ expdp mkuser/passwd@develop DIRECTORY=backup_dir DUMPFILE=develop.dmp LOGFILE=develop_backup.log
```


## 3. SQL

### 1) object 조회 SQL

dictionary 뷰에서부터 object 정보를 확인하고 생성된 상태를 확인할 수 있습니다.
sqlgate 에 단축키로 등록하고 사용하면 유용할 query 입니다.

```
# 테이블 검색
SELECT /* (Alt+1) 테이블 검색  */ A.OWNER, A.COMMENTS AS T_COMMENT, A.TABLE_NAME AS T_NAME, B.COLUMN_NAME AS C_NAME, B.COMMENTS AS C_COMMENT, B1.COLUMN_ID
FROM  ALL_TAB_COMMENTS A, ALL_COL_COMMENTS B, ALL_TAB_COLS B1
WHERE 1=1
  AND A.TABLE_NAME LIKE '%&Var%'
  AND A.TABLE_NAME = B.TABLE_NAME
  AND B.TABLE_NAME = B1.TABLE_NAME
  AND B.COLUMN_NAME = B1.COLUMN_NAME
  AND A.OWNER = B.OWNER
  AND B.OWNER = B1.OWNER(+)
  AND A.OWNER IN ('SPADBA')
ORDER BY A.OWNER DESC, B1.COLUMN_ID, A.COMMENTS
;

# 컬럼 검색
SELECT /* (Alt+2) 컬럼 검색  */ A.OWNER, A.COMMENTS AS T_COMMENT, A.TABLE_NAME AS T_NAME, B.COLUMN_NAME AS C_NAME, B.COMMENTS AS C_COMMENT, B1.COLUMN_ID
FROM  ALL_TAB_COMMENTS A, ALL_COL_COMMENTS B, ALL_TAB_COLS B1, ALL_CONS_COLUMNS C
WHERE 1=1
  AND (B.COLUMN_NAME LIKE '%&Var%' OR B.COMMENTS LIKE '%&Var%')
  AND A.TABLE_NAME = B.TABLE_NAME
  AND B.TABLE_NAME = C.TABLE_NAME(+)
  AND B.TABLE_NAME = B1.TABLE_NAME
  AND B.COLUMN_NAME = B1.COLUMN_NAME
  AND A.OWNER = B.OWNER
  AND B.OWNER = B1.OWNER(+)
  AND B.OWNER = C.OWNER
  AND B.COLUMN_NAME = C.COLUMN_NAME(+)
  AND C.CONSTRAINT_NAME(+) LIKE '%PK'
  AND A.OWNER IN ('SPADBA')
  AND (A.TABLE_NAME LIKE 'E%' OR A.TABLE_NAME LIKE 'CB%')
ORDER BY A.OWNER DESC, A.COMMENTS, B1.COLUMN_ID, C.POSITION
;

# 테이블 조회
SELECT /* (Alt+3) 테이블 조회 */ * FROM &Var WHERE ROWNUM < 200
;

# dict 검색
SELECT /* (Alt+4) DICT 검색 */ * FROM DICT WHERE TABLE_NAME LIKE '%'||'&Var'||'%'
ORDER BY TABLE_NAME
;
```
