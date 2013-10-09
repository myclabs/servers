# Configuration des serveurs

- Debian 7.0
- Apache
- MySQL
- PHP 5.5 + OpCache + APCu
- phpMyAdmin
- Supervisor : gestion des processus démons (workers, …)
- RabbitMQ : serveur de file de messages, utilisé pour les workers
- remote_syslog : envoie les logs à [PaperTrail](https://papertrailapp.com/), notre outil de lecture des logs

## Lancer le script

```shell
$ ./install.sh <SERVER_NAME> <MYSQL_ROOT_PASSWORD> <MYSQL_MYCSENSE_PASSWORD> <PHPMYADMIN_PASSWORD>
```

- `SERVER_NAME` : par ex. `dev.myc-sense.com`
- `MYSQL_ROOT_PASSWORD` : mot de passe `root` mysql
- `MYSQL_MYCSENSE_PASSWORD` : mot de passe `myc-sense` mysql
- `PHPMYADMIN_PASSWORD` : mot de passe d'admin phpMyAdmin

Le script peut demander à un moment de s'identifier pour GitHub.

## Déployer sur un serveur

Installer en tant que **root**!

```shell
$ ssh root@monserver
$ git clone https://github.com/myclabs/servers.git
$ cd servers/
$ ./install.sh ...
```

## Tester la configuration en local dans vagrant

Pour démarrer la machine virtuelle et lancer l'installation :

```shell
$ vagrant up
$ vagrant ssh
$ cd /vagrant
$ sudo ./install.sh ...
```
