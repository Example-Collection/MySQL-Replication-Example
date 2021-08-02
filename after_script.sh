# CREATE REPLICATION USER IN MASTER

docker exec -it mysql-replication_master_1 mysql -u root -e "CREATE USER IF NOT EXISTS 'repl_user'@'%' IDENTIFIED BY 'slavepass'"
docker exec -it mysql-replication_master_1 mysql -u root -e "GRANT REPLICATION SLAVE ON *.* TO 'repl_user'@'%'"


# SET MASTER FROM SLAVE

## DUMP MASTER DATABASE
docker exec -it mysql-replication_master_1 mysqldump -u root --opt --single-transaction --hex-blob --master-data=2 --routines --triggers --all-databases > master_data.sql 

## GENERATE SET MASTER QUERY

MASTER_QUERY_HEAD=$(cat master_data.sql | grep "CHANGE MASTER TO MASTER_LOG_FILE")
MASTER_QUERY_HEAD=${MASTER_QUERY_HEAD:3:(-2)}

MASTER_IP=$(docker inspect -f "{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}" mysql-replication_master_1)

SET_MASTER_QUERY=$MASTER_QUERY_HEAD,"master_host=""'"$MASTER_IP"'","master_port=3306","master_user='repl_user', master_password='slavepass'"
echo $SET_MASTER_QUERY

## RUN SET MASTER QUERY
docker exec -it mysql-replication_slave_1 mysql -u root -e "$SET_MASTER_QUERY"
docker exec -it mysql-replication_slave_1 mysql -u root -e "START SLAVE"
