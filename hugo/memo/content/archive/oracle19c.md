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
sqlplus sys as sysdba

# 데이터베이스 상태 확인
SQL> SELECT STATUS FROM V$INSTANCE;

# 현재 세션을 CDB 로 변경하고, 변경 여부 확인
SQL> ALTER SESSION SET CONTAINER = CDB$ROOT;
SQL> SHOW CON_NAME;

# pdb 생성
SQL> CREATE PLUGGABLE DATABASE market ADMIN USER pdb_market IDENTIFIED BY 1 FILE_NAME_CONVERT = ('/opt/oracle/oradata/ORCLCDB', '/opt/oracle/oradata/ORCLCDB/market');

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
alter session set "_oracle_script"=true;
CREATE USER mkuser IDENTIFIED BY 1;

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
```


#### 2. oracle19c 환경 정보

```
# 설치 경로(디렉토리) 확인
# cat /etc/oratab
ORCLCDB:/opt/oracle/product/19c/dbhome_1:Y

# 서비스명 확인
# systemctl list-units | grep oracle
oracledb_ORCLCDB-19c.service  loaded active running   SYSV: This script is responsible for taking care of configuring the Oracle Database and its associated services.

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