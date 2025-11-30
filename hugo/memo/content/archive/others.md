# TOOLS

## `erwin`
### database connection

우선 display 를 `물리 모델`로 변경합니다.

상단 메뉴 `Database` > `Database Connection` 선택하면 아래 팝업 창이 열립니다.

`Connection String:` 의 값은 tnsnames.ora 에 등록된 항목으로 입력합니다.

## `dnf`
### dnf-makecache 오류
`dnf-makecache`는 centos의 자동업데이트 기능입니다.
`오류: repo 'appstream': Cannot prepare internal mirrorlist: No URLs in mirrorlist 를 위해 메타데이타 내려받기에 실패하였습니다`
disable 명령어는 다음과 같습니다.
```
$ gsettings set org.gnome.software download-updates false
$ systemctl disable dnf-makecache.service
$ systemctl disable dnf-makecache.timer
```

정상 작동하도록 하기 위해 yum 저장소 설정 파일을 수정합니다.
```
$ sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-Linux-*
$ sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-Linux-*
```

## `sh`
### zsh (on centos)
```
$ yum install zsh
$ sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
$ vi ~/.zshrc
ZSH_THEME="agnoster"
$ git clone https://github.com/powerline/fonts.git
$ cd fonts && ./install.sh
$ git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions
$ git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
$ vi ~/.zshrc
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
)
```

```
$ vi ~/.oh-my-zsh/themes/agnoster.zsh-theme

prompt_newline() {
  if [[ -n $CURRENT_BG ]]; then
    echo -n "%{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR
%{%k%F{blue}%}$SEGMENT_SEPARATOR"
  else
    echo -n "%{%k%}"
  fi

  echo -n "%{%f%}"
  CURRENT_BG=''
}

build_prompt() {
  RETVAL=$?
  prompt_status
  prompt_virtualenv
  prompt_context
  prompt_dir
  prompt_git
  prompt_hg
  prompt_newline
  prompt_end
}
```

### zsh (on git-bash)

zsh-{버전}-x86_64.pkg.tar.zst 링크를 아래 사이트에서 다운로드 합니다.

<a href="https://packages.msys2.org/package/zsh?repo=msys&variant=x86_64" target="_blank">링크</a>

zstandard(`zstd`)가 설치되어 있어야 압축해제가 가능합니다.

git-bash 설치 경로 `C:\Program Files\Git` 에서 압축을 해제합니다. (`usr`, `etc` 디렉토리에 덮어쓰기)

```
$ sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
$ cat << EOF > ~/.bashrc
exec zsh
EOF
$ vi ~/.oh-my-zsh/themes/agnoster.zsh-theme
prompt_newline() {
  if [[ -n $CURRENT_BG ]]; then
    echo -n "%{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR
%{%k%F{blue}%}$SEGMENT_SEPARATOR"
  else
    echo -n "%{%k%}"
  fi

  echo -n "%{%f%}"
  CURRENT_BG=''
}

build_prompt() {
  RETVAL=$?
  prompt_status
  prompt_virtualenv
  prompt_context
  prompt_dir
  prompt_git
  prompt_hg
  prompt_newline
  prompt_end
}
$ vi ~/.zshrc
ZSH_THEME="agnoster"
```

`git-bash` > `Options` > `Looks` > `Theme` 에서 `rosipov` 선택합니다.


## `cockpit`
### cockpit 설치
cockpit 은 centos 의 web console 을 제공하는 패키지 입니다.

```
$ dnf install cockpit
$ systemctl enable --now cockpit.socket
$ netstat -ntplu | grep 9090
```

cockpit 에 ssl 인증서 교체하기
```
# create-cert.sh 로 인증서를 생성합니다.
# 인자는 web console 에 접근할 도메인으로 생성하면 됩니다.
# 예시는 centos8 이라는 도메인으로 생성합니다.
$ ./create-cert.sh centos8
$ ls -al 
-rw-r--r--  1 root root 1310  1월  2 14:58 centos8.crt
-rw-------  1 root root 1708  1월  2 14:58 centos8.key
$ cd /etc/cockpit/ws-certs.d
$ ls -al
-rw-r--r--  1 root root       2094  1월  2 00:46 0-self-signed-ca.pem
-rw-r--r--  1 root root       1684  1월  2 00:46 0-self-signed.cert
-rw-r-----  1 root cockpit-ws 1704  1월  2 00:46 0-self-signed.key
$ cp centos8.crt centos8.key /etc/cockpit/ws-certs.d
$ chmod 640 centos8.key
$ chown root:cockpit-ws centos8.key
$ chmod 644 centos8.crt
$ remotectl certificate centos8.crt centos8.key
generated combined certificate file: /etc/cockpit/ws-certs.d/centos8.cert
$ remotectl certificate
certificate: /etc/cockpit/ws-certs.d/centos8.crt
$ systemctl restart cockpit
```

centos8 인증서 등록하기

`https://centos8:9090/` 링크로 이동하면 신뢰할 수 없는 사이트라고 표시됩니다.

인증서를 내보내기 한 다음 아래 절차대로 인증서를 등록합니다.

- chrome 에서 `chrome://settings/security?q=enhanced` 링크로 이동합니다.
- `인증서 관리` 메뉴를 클릭하면 팝업이 열립니다.
- `신뢰할 수 있는 루트 인증 기관` 탭에서 가져오기를 클릭 합니다.
- 내보내기 한 인증서를 선택하고 가져오기를 합니다.
- chrome 에서 `chrome://net-internals/#hsts` 링크로 이동합니다.
- `Delete domain security policies` 에서 `centos8` 을 입력하고 `Delete` 버튼을 클릭합니다.
- chrome 에서 `chrome://restart` 링크 이동으로 chrome 을 재시작합니다.
- chrome 에서 `https://centos8:9090/` 링크로 이동하여 정상 작동하는지를 확인합니다.


listen-port 변경하기

`/etc/systemd/system/sockets.target.wants/cockpit.socket` 파일을 아래와 같이 편집합니다.

```
[Unit]
Description=Cockpit Web Service Socket
Documentation=man:cockpit-ws(8)
Wants=cockpit-motd.service

[Socket]
#ListenStream=9090 # 기본값
ListenStream=127.0.0.1:8000  # 변경값 (httpd 에서 proxy 로 접근)
ExecStartPost=-/usr/share/cockpit/motd/update-motd '' localhost
ExecStartPost=-/bin/ln -snf active.motd /run/cockpit/motd
ExecStopPost=-/bin/ln -snf inactive.motd /run/cockpit/motd

[Install]
WantedBy=sockets.target
```

redhat 공식문서에서는 `/etc/systemd/system/cockpit.socket.d/listen.conf` 파일을 `생성`하고 daemon-reload 를 하라고 되어있습니다.

```
[Socket]
ListenStream=
ListenStream=127.0.0.1:8000
FreeBind=yes
```

```
If an IP address is used here, it is often desirable to listen on it before the interface it is configured on is up and running, and even regardless of whether it will be up and running at any point. To deal with this, it is recommended to set the FreeBind= option described below.
```

편집 후 아래 명령어를 실행합니다.

```
$ systemctl daemon-reload cockpit.socket
$ systemctl restart cockpit.socket
# 변경 상태를 확인합니다.
$ netstat -ntplu | grep 8000
```

### cockpit-pcp 설치
시스템 모니터링 기능이며 `cockpit-pcp`를 설치하여 메트릭 정보를 볼 수 있습니다.
```
$ yum install cockpit-pcp
$ systemctl enable pmlogger.service
$ systemctl enable pmproxy.service
$ systemctl daemon-reload
$ systemctl start pmlogger.service
$ systemctl start pmproxy.service
```
pmproxy.service 활성화를 통해 여러 머신의 메트릭 정보를 볼 수도 있습니다. (redis 설치됨)



### grafana, grafana-pcp
```
$ yum install grafana grafana-pcp
$ systemctl enable --now grafana-server
```
http://host:3000/ 으로 접속
포트 변경은 `/etc/grafana/grafana.ini` 파일에서 `http_port = 3000` 를 변경하면 됩니다.
서비스 재시작: `systemctl restart grafana-server`


- 로그인 후 설정
  - 좌측 메뉴 `Configuration` > `Plugin` 선택
  - `Performance Co-Pilot` 플러그인을 활성화 (enable 버튼 클릭)
  - `cockpit-pcp`에서 `redis` 설치 후 `grafana`에서 `Configuration` > `Data Sources` 선택
    <br>(`grafana`는 cockpit-pcp 의 메트릭 정보를 redis 를 통해 가져옵니다. redis 설치는 cockpit 에서 버튼 클릭 한번으로 끝남)
  - `HTTP`의 `URL` 항목만 `http://127.0.0.1:44322` 으로 입력 후 `Save & Test` 버튼 클릭


## `jenkins`
### AnsiColor 플러그인
플러그인 설치 후 개별 job 의 `구성`에서 `빌드 환경`에 `Color ANSI Console Output` 을 선택하면 됩니다.
플러그인 설명은 `Adds ANSI coloring to the Console Output` 입니다.


#### (win) 절전 cmd

```
%windir%\System32\rundll32.exe powrprof.dll SetSuspendState
```

#### (vmware) 실행 cmd

```
set "VMWARE_HOME=C:\Program Files (x86)\VMware\VMware Workstation"
set "PATH=%PATH%;%VMWARE_HOME%"
vmrun -T ws start "Z:\centos7-develop\centos7-develop.vmx" nogui
```


#### (jmeter) jmeter 실행 cmd

jmeter 실행 결과 디렉토리에 timestamp 변수 사용하기

```
> set ts=%DATE:~0,4%%DATE:~5,2%%DATE:~8,2%_%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%
> apache-jmeter-5.4.1\bin\jmeter.bat -n -t jmeter-mgkim-core.jmx -l data\%ts%.csv -e -o data\%ts%
```



#### (oracle12) oracle 계정 생성

```
alter session set "_oracle_script"=true;
CREATE TABLESPACE TS_DATA01 DATAFILE '/data/DB/oradata/ora12c/SPADBP/TS_DATA01.dbf' SIZE 1G AUTOEXTEND ON NEXT 10M;
CREATE USER SPADBA IDENTIFIED BY 1 DEFAULT TABLESPACE TS_DATA01;
CREATE USER SPAAPP IDENTIFIED BY SPAAPP1234 DEFAULT TABLESPACE TS_DATA01;
ALTER USER SPADBA QUOTA UNLIMITED ON TS_DATA01;
GRANT CONNECT, RESOURCE, CREATE VIEW, EXP_FULL_DATABASE, IMP_FULL_DATABASE, DBA TO SPADBA;
CREATE ROLE RL_SPA_APP;
GRANT CONNECT, RESOURCE TO RL_SPA_APP;
GRANT RL_SPA_APP TO SPAAPP;
```

#### (oracle12) imp/exp

```
exp.exe SPADBA/1@SPADBP FILE='Z:\SPADBP.dmp' GRANTS=Y INDEXES=Y ROWS=Y CONSTRAINTS=Y TRIGGERS=N COMPRESS=Y DIRECT=N CONSISTENT=N OWNER=(SPADBA)
imp.exe SPADBA/1@SPADBP FILE='Z:\SPADBP.dmp' FEEDBACK=1000 GRANTS=Y INDEXES=Y ROWS=Y CONSTRAINTS=Y IGNORE=N SHOW=N DESTROY=N ANALYZE=Y SKIP_UNUSABLE_INDEXES=N RECALCULATE_STATISTICS=N FROMUSER=SPADBA TOUSER=SPADBA
```

#### (oracle12) drop table 문

```
select 'drop table '||table_name||' cascade constraints;' from user_tables;
```

#### (oracle12) character-set 설정

```
select * from nls_database_parameters where parameter like '%NLS_CHARACTERSET%';
/**
NLS_CHARACTERSET  WE8MSWIN1252
**/
/**
NLS_CHARACTERSET  AL32UTF8
*/

SHUTDOWN IMMEDIATE;
STARTUP MOUNT;
ALTER SYSTEM ENABLE RESTRICTED SESSION;
ALTER SYSTEM SET JOB_QUEUE_PROCESSES=0;
ALTER SYSTEM SET AQ_TM_PROCESSES=0;
ALTER DATABASE OPEN;
ALTER DATABASE CHARACTER SET INTERNAL_USE AL32UTF8;
SHUTDOWN IMMEDIATE;
STARTUP;
```



### 4. 예시
#### 1) vhost-jenkins.conf
```apacheconf
<VirtualHost *:80>
  ServerName jenkins.develop.net
  
  RewriteEngine On
  RewriteCond %{HTTPS} !=On
  RewriteCond %{REQUEST_URI} ^/(computer)/.*$
  RewriteRule /(.*) http://localhost:8400/$1 [QSA,P,L]
  RewriteCond %{REQUEST_URI} ^/(wsagents)/.*$
  RewriteRule /(.*) ws://localhost:8400/$1 [QSA,P,L]
  
  RewriteRule /(.*) https://jenkins.develop.net/$1 [QSA,R,L]
</VirtualHost>

<VirtualHost *:443>
  ServerName jenkins.develop.net
  
  AllowEncodedSlashes On
  Header set Access-Control-Allow-Origin "*"
  
  RewriteEngine On
  RewriteCond %{HTTP:Upgrade} =websocket [NC]
  RewriteRule /(.*) ws://localhost:8400/$1 [P,L]
  RewriteCond %{HTTP:Upgrade} !=websocket [NC]
  RewriteRule /(.*) http://localhost:8400/$1 [P,L]
</VirtualHost>
```