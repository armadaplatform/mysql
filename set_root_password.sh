#!/bin/bash

if [ ! -n "${MYSQL_ROOT_PASSWORD}" ]; then
    MYSQL_ROOT_PASSWORD=groovy
fi

/usr/bin/mysqld_safe > /dev/null 2>&1 &

RET=1
while [[ RET -ne 0 ]]; do
    echo "=> Waiting for confirmation of MySQL service startup"
    sleep 5
    mysql -uroot -e "status" > /dev/null 2>&1
    RET=$?
done

mysql -u root -e "CREATE USER 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}'"
mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION"
mysql -u root -e "CREATE USER 'healthcheck'@'localhost'"
mysql -u root -e "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('${MYSQL_ROOT_PASSWORD}')"

echo "=> Done!"
mysqladmin -u root shutdown
