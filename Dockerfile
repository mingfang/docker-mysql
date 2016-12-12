FROM ubuntu:16.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    TERM=xterm
RUN locale-gen en_US en_US.UTF-8
RUN echo "export PS1='\e[1;31m\]\u@\h:\w\\$\[\e[0m\] '" >> /root/.bashrc
RUN echo "export PS1='\e[1;31m\]\u@\h:\w\\$\[\e[0m\] '" >> /etc/bash.bashrc
RUN apt-get update

# Runit
RUN apt-get install -y --no-install-recommends runit
CMD export > /etc/envvars && /usr/sbin/runsvdir-start
RUN echo 'export > /etc/envvars' >> /root/.bashrc

# Utilities
RUN apt-get install -y --no-install-recommends vim less net-tools inetutils-ping wget curl git telnet nmap socat dnsutils netcat tree htop unzip sudo software-properties-common jq psmisc iproute python ssh

#Nginx
RUN apt-get install -y nginx

#MySQL
RUN wget http://dev.mysql.com/get/mysql-apt-config_0.8.0-1_all.deb && \
    dpkg -i *.deb && \
    apt-get update
RUN apt-get install -y mysql-server

#PHP-FPM
RUN apt-get install -y php-fpm php-mysql php-mbstring 
RUN sed -i "s|;cgi.fix_pathinfo=1|cgi.fix_pathinfo=0|" /etc/php/7.0/fpm/php.ini

#phpAdmin
RUN wget -O - https://files.phpmyadmin.net/phpMyAdmin/4.6.5.2/phpMyAdmin-4.6.5.2-all-languages.tar.gz | tar zx -C /var/www/html --strip-components=1

#memcached plugin
RUN apt-get install -y libevent-dev

#configuration
RUN sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mysql/my.cnf
COPY custom.cnf /etc/mysql/conf.d/

COPY config.inc.php /var/www/html
COPY default /etc/nginx/sites-enabled/

#data
COPY mysql.ddl /
#COPY data.sql /
RUN mysqld_safe & mysqladmin --wait=5 ping && \
    mysql < /usr/share/mysql/innodb_memcached_config.sql && \
    mysql < mysql.ddl && \
#    mysql -u root < data.sql && \
    mysqladmin shutdown

# Add runit services
COPY sv /etc/service 
ARG BUILD_INFO
LABEL BUILD_INFO=$BUILD_INFO
