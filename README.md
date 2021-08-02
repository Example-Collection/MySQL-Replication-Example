# MySQL 복제 구축 예시

## 실행 방법

```
docker-compose up -d
chmod +x after_script.sh
./after_script.sh
```

* 각 컨테이너의 mysql client로 접속하여 동기화가 되는 것을 확인할 수 있습니다

## MYSQLD 설정

### MASTER 설정
```cnf
[mysqld]
server-id = 1
log-bin = binary_log
sync_binlog = 1
binlog_cache_size = 5M
max_binlog_size = 512M
expire_logs_days = 14
log-bin-trust-function-creators = 1
```

* master와 slave는 각각 다른 server_id 값을 가져야한다
* master는 반드시 바이너리 로그가 활성화 돼있어야 한다

* `log-bin = binary_log`: 바이너리 로그를 활성화하는 옵션. 값으로 `binary_log`이 주어졌으므로 파일명 prefix는 `binary_log`입니다
* `sync_binlog = 1`: 하나의 트랜잭션이 성공할 때마다 바이너리 로그를 디스크로 flush 합니다

### SLAVE 설정
```cnf
[mysqld]
server-id = 2
relay-log = relay_log
relay_log_purge = TRUE
read_only
```

* `relay_log_purge = TRUE`: 불필요한 relay_log를 삭제합니다
* `read_only`: SUPER PRIVILEGE가 없는 유저들은 읽기만 가능합니다

## 복제 계정 준비

* slave가 master의 데이터를 동기화할 때 사용할 계정을 생성해야 합니다
* 해당 계정에 `REPLICATION SLAVE` 권한을 줘야 합니다

## 데이터 복사

* mysqldump 또는 MySQL Enterprise backup을 통해 master의 데이터를 slave로 복사해야 합니다
```
mysqldump -u root -p --opt --single-transaction --hex-blob --master-data=2 --routines --triggers --all-databases > master_data.sql
```

* `--single-transaction`: 레코드 잠금을 걸지 않고 InnoDB의 테이블을 백업할 수 있게 해줍니다
* 백업이 시작하는 지점의 바이너리 로그 정보를 알 수 있어야 하는데, `--master-data=2` 옵션으로 바이너리 로그의 정보를 백업 파일에 같이 저장할 수 있습니다
* `master-data` 옵션은 mysqldump 프로그램이 글로벌 리드 락을 걸게 합니다

## 복제 시작

* slave 서버에서 master를 설정해줍니다
```
CHANGE MASTER TO MASTER_LOG_FILE='binary_log.00000/',
    MASTER_LOG_POS=4, master_host=xxx.xxx.xxx.xxx, master_port=3306,
    master_user=repl_user, master_password=repl_password;

START SLAVE;
```

* `START SLAVE` 쿼리를 실행한 뒤, `SHOW SLAVE STATUS\G`로 실행 상태를 확인할 수 있다