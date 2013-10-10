# Gestion des serveurs

## Script de configuration du serveur

- Debian 7.0
- Apache
- MySQL
- PHP 5.5 + OpCache + APCu
- phpMyAdmin
- Supervisor : gestion des processus démons (workers, …)
- RabbitMQ : serveur de file de messages, utilisé pour les workers
- remote_syslog : envoie les logs à [PaperTrail](https://papertrailapp.com/), notre outil de lecture des logs

```shell
$ ./install.sh <SERVER_NAME> <MYSQL_ROOT_PASSWORD> <PASSWORD>
```

- `SERVER_NAME` : par ex. `dev.myc-sense.com`
- `MYSQL_ROOT_PASSWORD` : mot de passe `root` mysql
- `PASSWORD` : mot de passe `myc-sense` mysql et RabbitMQ

Le script demandera à un moment de s'identifier pour GitHub.

### Déployer sur un serveur

Installer en tant que **root**!

```shell
$ ssh root@monserver
$ git clone https://github.com/myclabs/servers.git
$ cd servers/
$ ./install.sh ...
```

### Tester la configuration en local dans vagrant

Pour démarrer la machine virtuelle et lancer l'installation :

```shell
$ vagrant up
$ vagrant ssh
$ cd /vagrant
$ sudo ./install.sh ...
```

## Script d'installation d'Inventory

```shell
$ ./create_project.sh <NAME> <ENV> <SHORT_ENV> <PASSWORD>
```

- `NAME` : par ex. `inventory1` ou `bollore`
- `ENV` : environnement complet : `developpement`, `production`…
- `SHORT_ENV` : environnement cours (pour le nom du serveur) : `dev`, `prod`…
- `PASSWORD` : mot de passe `myc-sense` mysql et RabbitMQ
