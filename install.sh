#!/bin/sh
set -e

CURRENT_DIR=`pwd`

if [ $# -ne 3 ]
then
    echo "Usage: $0 SERVER_NAME MYSQL_ROOT_PASSWORD PASSWORD" 1>&2
    echo "Example: $0 test.myc-sense.com bbbaaaeee aaabbbccc" 1>&2
    echo "Password is for MySQL (user myc-sense) and RabbitMQ" 1>&2
    exit 1
fi

SERVER_NAME=$1
MYSQL_ROOT_PASSWORD=$2
PASSWORD=$3
NEW_RELIC_KEY=1f9b4f1bfee1c5ee9c6891fd28c60a4134302838


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

apt-get install -y zsh curl git rabbitmq-server supervisor memcached python-pip

# Mysql
export DEBIAN_FRONTEND=noninteractive
echo "mysql-server mysql-server/root_password password $MYSQL_ROOT_PASSWORD" | debconf-set-selections
echo "mysql-server mysql-server/root_password_again password $MYSQL_ROOT_PASSWORD" | debconf-set-selections
apt-get install -q -y mysql-server
mysql -u root -p$MYSQL_ROOT_PASSWORD -e "CREATE USER 'myc-sense'@'localhost' IDENTIFIED BY '$PASSWORD';"
mysql -u root -p$MYSQL_ROOT_PASSWORD -e "GRANT ALL PRIVILEGES ON *.* TO 'myc-sense'@'localhost';"
mysql -u root -p$MYSQL_ROOT_PASSWORD -e "FLUSH PRIVILEGES;"

apt-get install -y apache2 php5 php5-curl php5-cli php5-gd php5-mcrypt php5-dev php5-mysql php-pear php5-memcached

# PHP
cp configs/php/apache2/php.ini /etc/php5/apache2/php.ini
cp configs/php/cli/php.ini /etc/php5/cli/php.ini

cat > /etc/apache2/sites-enabled/000-default.conf <<CONF
<VirtualHost *:80>
        ServerName $SERVER_NAME

        ServerAdmin webmaster@localhost
        DocumentRoot /var/www

        LogLevel warn
        ErrorLog \${APACHE_LOG_DIR}/error.log
        CustomLog \${APACHE_LOG_DIR}/access.log combined

        <Directory "/var/www">
                AllowOverride all
                Order allow,deny
                Allow from all
                Options +Indexes +FollowSymLinks +MultiViews
        </Directory>
</VirtualHost>
CONF

# phpMyAdmin
export DEBIAN_FRONTEND=noninteractive
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections
echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/admin-pass $MYSQL_ROOT_PASSWORD" | debconf-set-selections
echo "phpmyadmin phpmyadmin/app-password-confirm $PASSWORD" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/app-pass $PASSWORD" | debconf-set-selections
apt-get install -q -y phpmyadmin
ln -s /etc/phpmyadmin/apache.conf /etc/apache2/conf-enabled/phpmyadmin.conf

# Apache
a2enmod rewrite
apachectl restart

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
cd $CURRENT_DIR

# Système de logs
apt-get install -y ruby ruby-dev
gem install remote_syslog

mkdir -p /etc/logs/logs
cat > /etc/logs/config.yml <<CONF
files:
  - /var/log/supervisor/supervisord.log
  - /etc/logs/logs/*
hostname: $SERVER_NAME
destination:
  host: logs.papertrailapp.com
  port: 14028
CONF

cp configs/supervisor/logs.conf /etc/supervisor/conf.d/logs.conf
supervisorctl reload

# RabbitMQ
rabbitmq-plugins enable rabbitmq_management
rabbitmqctl delete_user guest
rabbitmqctl add_user myc-sense $PASSWORD
rabbitmqctl set_user_tags myc-sense administrator
rabbitmqctl set_permissions -p "/" "myc-sense" ".*" ".*" ".*"
/etc/init.d/rabbitmq-server restart

# New Relic
wget -O - http://download.newrelic.com/548C16BF.gpg | apt-key add -
echo "deb http://apt.newrelic.com/debian/ newrelic non-free" > /etc/apt/sources.list.d/newrelic.list
apt-get update
apt-get install -y newrelic-sysmond newrelic-php5
nrsysmond-config --set license_key=$NEW_RELIC_KEY
/etc/init.d/newrelic-sysmond start
export NR_INSTALL_SILENT=true
export NR_INSTALL_KEY=$NEW_RELIC_KEY
newrelic-install install
apachectl restart

# New-Relic plugins
pip install newrelic-plugin-agent
cp configs/newrelic/newrelic_plugin_agent.cfg /etc/newrelic/newrelic_plugin_agent.cfg
sed -e "s/REPLACE_WITH_REAL_KEY/$NEW_RELIC_KEY/" /etc/newrelic/newrelic_plugin_agent.cfg
sed -e "s/RABBITMQ_USER/myc-sense/" /etc/newrelic/newrelic_plugin_agent.cfg
sed -e "s/RABBITMQ_PASSWORD/$PASSWORD/" /etc/newrelic/newrelic_plugin_agent.cfg
sed -e "s/SERVER_NAME/$SERVER_NAME/" /etc/newrelic/newrelic_plugin_agent.cfg
cp /opt/newrelic_plugin_agent/newrelic_plugin_agent.deb /etc/init.d/newrelic_plugin_agent
chmod +x /etc/init.d/newrelic_plugin_agent
update-rc.d newrelic_plugin_agent defaults # auto start at boot
/etc/init.d/newrelic_plugin_agent start # launch

mkdir /home/web
