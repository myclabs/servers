# Configuration des serveurs

- Debian 7.0
- Apache
- MySQL
- PHP 5.5 + OpCache + APCu
- RabbitMQ
- phpMyAdmin

## Lancer le script

```shell
$ ./install.sh <MYSQL_ROOT_PASSWORD> <MYSQL_MYCSENSE_PASSWORD> <PHPMYADMIN_PASSWORD>
```

## Tester la configuration en local dans vagrant

Pour démarrer la machine virtuelle et lancer l'installation :

```shell
$ vagrant up
$ vagrant ssh
$ cd /vagrant
$ sudo ./install.sh ...
```

## Déployer sur un serveur

Installer en tant que **root**!

```shell
$ ssh root@monserver
$ git clone https://github.com/myclabs/servers.git
$ cd servers/
$ ./install.sh ...
```
