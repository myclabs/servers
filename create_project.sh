#!/bin/sh
set -e

if [ $# -ne 4 ]
then
    echo "Usage: $0 NAME ENV SHORT_ENV PASSWORD" 1>&2
    echo "Example: $0 inventory1 developpement dev aaabbbccc" 1>&2
    echo "Password is for MySQL (user myc-sense) and RabbitMQ" 1>&2
    exit 1
fi

NAME=$1
ENV=$2
SHORT_ENV=$3
# Password for MySQL and RabbitMQ
PASSWORD=$4

DIR_WEB=/home/web

git clone git@github.com:myclabs/Inventory.git /home/web/$NAME
cd /home/web/$NAME
composer install --no-dev

cp public/.htaccess.default public/.htaccess
cp application/configs/env.php.default application/configs/env.php

sed -i "s/#RewriteBase \/inventory\//RewriteBase \/$NAME\//" public/.htaccess
sed -i "s/production/$ENV/" application/configs/env.php
cat > application/configs/application.ini <<CONF
[production]
applicationName = "$NAME"
sessionStorage.name = "$NAME"

doctrine.default.connection.user = 'myc-sense'
doctrine.default.connection.password = '$PASSWORD'
doctrine.default.connection.dbname = '$NAME'

rabbitmq.password = '$PASSWORD'

[test : production]
[developpement : test]
[testsunitaires : test]
CONF

touch data/logs/error.log
touch data/logs/queries.log
touch data/logs/worker.log

chmod 777 data/documents
chmod -R 777 data/logs
chmod 777 data/proxies
chmod -R 777 public/cache
chmod 777 public/temp

# Logs
ln -s /home/web/$NAME/data/logs/error.log /etc/logs/logs/$NAME-web.log
ln -s /home/web/$NAME/data/logs/worker.log /etc/logs/logs/$NAME-worker.log
supervisorctl restart logs

php scripts/build/build.php create update

# Start worker
supervisorctl update

ln -s /home/web/$NAME/public /var/www/$NAME
