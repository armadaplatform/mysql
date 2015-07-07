FROM microservice_php
MAINTAINER Cerebro <cerebro@ganymede.eu>, based on tutumcloud/tutum-docker-mysql

ENV MYSQL_APT_GET_UPDATE_DATE 2015-02-24
RUN apt-get update

# Install MySQL.
RUN apt-get install -y mysql-server-5.6
# Remove pre-installed database.
RUN rm -rf /var/lib/mysql/*

# Install phpMyAdmin.
RUN apt-get install -y phpmyadmin
RUN ln -s /etc/phpmyadmin/apache.conf /etc/apache2/sites-enabled/phpmyadmin.conf
RUN mkdir -p /opt/www && ln -s /usr/share/phpmyadmin /opt/www/www
RUN sed -ri 's/^session.gc_maxlifetime.*/session.gc_maxlifetime = 43200/g' /etc/php5/apache2/php.ini
RUN sed -ri 's/^post_max_size.*/post_max_size = 128M/g' /etc/php5/apache2/php.ini
RUN sed -ri 's/^upload_max_filesize.*/upload_max_filesize = 128M/g' /etc/php5/apache2/php.ini
ADD phpmyadmin_longer_session.php /etc/phpmyadmin/conf.d/
# Disable phpMyAdmin features that require own configuration database (which doesn't exist).
# https://wiki.phpmyadmin.net/pma/Configuration_storage
RUN rm -f /etc/phpmyadmin/config-db.php

ADD ./supervisor/mysql.conf /etc/supervisor/conf.d/
ADD ./supervisor/register_in_service_discovery.conf /etc/supervisor/conf.d/
ADD ./health-checks/mysql-ok /opt/microservice/health-checks/

# Add MySQL configuration.
ADD my.cnf /etc/mysql/conf.d/my.cnf
RUN chmod 644 /etc/mysql/conf.d/my.cnf

ADD . /opt/mysql
RUN chmod 755 /opt/mysql/*.sh

VOLUME ["/var/lib/mysql"]

EXPOSE 3306