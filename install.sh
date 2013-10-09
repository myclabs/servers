#!/bin/sh
set -e

CURRENT_DIR=`pwd`

if [ $# -ne 4 ]
then
    echo "Usage: $0 SERVER_NAME MYSQL_ROOT_PASSWORD MYSQL_MYCSENSE_PASSWORD PHPMYADMIN_PASSWORD" 1>&2
    exit 1
fi

SERVER_NAME=$1
MYSQL_ROOT_PASSWORD=$2
MYSQL_MYCSENSE_PASSWORD=$3
PHPMYADMIN_PASSWORD=$4


apt-get update

# For PHP 5.5
apt-get install -y software-properties-common
add-apt-repository -y ppa:ondrej/php5

# RabbitMQ
echo "deb http://www.rabbitmq.com/debian/ testing main" > /etc/apt/sources.list.d/rabbitmq.list
wget http://www.rabbitmq.com/rabbitmq-signing-key-public.asc
apt-key add rabbitmq-signing-key-public.asc
rm rabbitmq-signing-key-public.asc

apt-get update

apt-get install -y zsh curl git rabbitmq-server supervisor

# Mysql
export DEBIAN_FRONTEND=noninteractive
echo "mysql-server mysql-server/root_password password $MYSQL_ROOT_PASSWORD" | debconf-set-selections
echo "mysql-server mysql-server/root_password_again password $MYSQL_ROOT_PASSWORD" | debconf-set-selections
apt-get install -q -y mysql-server
mysql -u root -p$MYSQL_ROOT_PASSWORD -e "CREATE USER 'myc-sense'@'localhost' IDENTIFIED BY '$MYSQL_MYCSENSE_PASSWORD';"
mysql -u root -p$MYSQL_ROOT_PASSWORD -e "GRANT ALL PRIVILEGES ON *.* TO 'myc-sense'@'localhost';"
mysql -u root -p$MYSQL_ROOT_PASSWORD -e "FLUSH PRIVILEGES;"

apt-get install -y apache2 php5 php5-curl php5-cli php5-gd php5-mcrypt php5-dev php5-mysql php-pear php5-apcu

# PHP
cp configs/php/apache2/php.ini /etc/php5/apache2/php.ini
cp configs/php/cli/php.ini /etc/php5/cli/php.ini

# Apache
a2enmod rewrite
apachectl restart

# phpMyAdmin
export DEBIAN_FRONTEND=noninteractive
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections
echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/admin-pass $MYSQL_ROOT_PASSWORD" | debconf-set-selections
echo "phpmyadmin phpmyadmin/app-password-confirm $PHPMYADMIN_PASSWORD" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/app-pass $PHPMYADMIN_PASSWORD" | debconf-set-selections
apt-get install -q -y phpmyadmin

# Composer
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

# PHPUnit
pear config-set auto_discover 1
pear install pear.phpunit.de/PHPUnit

# Deploy
git clone https://github.com/myclabs/deploy.git /home/deploy
ln -s /home/deploy/bin/deploy /usr/local/bin/deploy
cd /home/deploy
composer install
cd CURRENT_DIR

# Système de logs
apt-get install libgemplugin-ruby
gem install remote_syslog

mkdir /etc/logs
cat > /etc/logs/general.yml <<CONF
files:
  - /var/log/supervisor/supervisord.log
hostname: $SERVER_NAME
destination:
  host: logs.papertrailapp.com
  port: 14028
CONF

cp configs/supervisor/general-logs.conf /etc/supervisor/conf.d/general-logs.conf
supervisorctl reload

mkdir /home/web
