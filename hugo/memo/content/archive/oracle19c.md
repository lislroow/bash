#### 5. dump 파일 import 하기

imp 명령어와 impdp 명령어가 있으며, exp 로 생성한 dump 는 imp 로 import 해야 함

```
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

```
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


#### 4. pdb 삭제

```
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


#### 3. 새로운 pdb 생성 및 계정 생성

##### 3.1 pdb 생성

```
# 접속
$ sqlplus sys as sysdba

# 데이터베이스 상태 확인
SQL> SELECT STATUS FROM V$INSTANCE;

# 현재 세션을 CDB 로 변경하고, 변경 여부 확인
SQL> ALTER SESSION SET CONTAINER = CDB$ROOT;
SQL> SHOW CON_NAME;

# pdb 생성
SQL> CREATE PLUGGABLE DATABASE market ADMIN USER pdb_market IDENTIFIED BY 1 FILE_NAME_CONVERT = ('/opt/oracle/oradata/ORCLCDB', '/opt/oracle/oradata/ORCLCDB/market');
SQL> CREATE PLUGGABLE DATABASE develop ADMIN USER pdb_market IDENTIFIED BY 1 FILE_NAME_CONVERT = ('/opt/oracle/oradata/ORCLCDB', '/opt/oracle/oradata/ORCLCDB/develop');

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

##### 3.2 새로운 pdb 에 user 생성

```
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


#### 2. oracle19c 환경 정보

```
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
    (ADDRESS =(PROTOCOL=TCP)(HOST=172.28.200.60)(PORT=1521)
  )
  (CONNECT_DATA =(SERVICE_NAME=orclpdb1)
  )
)
```


#### 1. oracle19c 설치

생략