FROM dockyard.armada.sh/microservice_php
MAINTAINER Cerebro <cerebro@ganymede.eu>, based on https://github.com/docker-library/mysql/

ENV MYSQL_APT_GET_UPDATE_DATE 2021-02-12
ENV MYSQL_VERSION=5.7.33

RUN wget https://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-server_${MYSQL_VERSION}-1ubuntu${DISTRIB_RELEASE}_amd64.deb -O /tmp/server.deb && \
    wget https://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-community-server_${MYSQL_VERSION}-1ubuntu${DISTRIB_RELEASE}_amd64.deb -O /tmp/community_server.deb && \
    wget https://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-common_${MYSQL_VERSION}-1ubuntu${DISTRIB_RELEASE}_amd64.deb -O /tmp/common.deb && \
    wget https://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-client_${MYSQL_VERSION}-1ubuntu${DISTRIB_RELEASE}_amd64.deb -O /tmp/client.deb && \
    wget https://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-community-client_${MYSQL_VERSION}-1ubuntu${DISTRIB_RELEASE}_amd64.deb -O /tmp/community_client.deb

RUN apt-get update
RUN apt-get install -y libaio1 libaio-dev libmecab2 apparmor libnuma1

RUN cd /tmp && dpkg -i common.deb community_client.deb client.deb community_server.deb server.deb && rm *.deb

# Remove pre-installed database.
RUN rm -rf /var/lib/mysql/*

# comment out a few problematic configuration values
# don't reverse lookup hostnames, they are usually another container
RUN sed -Ei 's/^(bind-address|log)/#&/' /etc/mysql/mysql.conf.d/mysqld.cnf \
&& echo '[mysqld]\nskip-host-cache\nskip-name-resolve' > /etc/mysql/conf.d/docker.cnf

RUN echo "phpmyadmin phpmyadmin/internal/skip-preseed boolean true" | debconf-set-selections
RUN echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect" | debconf-set-selections
RUN echo "phpmyadmin phpmyadmin/dbconfig-install boolean false" | debconf-set-selections
RUN apt-get install -y phpmyadmin

RUN ln -s /etc/phpmyadmin/apache.conf /etc/apache2/sites-enabled/phpmyadmin.conf
RUN mkdir -p /opt/www && ln -s /usr/share/phpmyadmin /opt/www/www
RUN sed -ri 's/^session.gc_maxlifetime.*/session.gc_maxlifetime = 43200/g' /etc/php/5.6/apache2/php.ini
RUN sed -ri 's/^post_max_size.*/post_max_size = 128M/g' /etc/php/5.6/apache2/php.ini
RUN sed -ri 's/^upload_max_filesize.*/upload_max_filesize = 128M/g' /etc/php/5.6/apache2/php.ini
ADD phpmyadmin_longer_session.php /etc/phpmyadmin/conf.d/

# Disable phpMyAdmin features that require own configuration database (which doesn't exist).
# https://wiki.phpmyadmin.net/pma/Configuration_storage
RUN rm -f /etc/phpmyadmin/config-db.php

ADD ./supervisor/* /etc/supervisor/conf.d/
ADD . /opt/mysql

## Add MySQL configuration
RUN cat /opt/mysql/my.cnf >> /etc/mysql/my.cnf
RUN chmod 755 /opt/mysql/*.sh

VOLUME ["/var/lib/mysql"]

EXPOSE 3306
