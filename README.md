# Gestion des serveurs

## Avant

Avant de lancer le script, il y'a quelques étapes :

- `apt-get install git`
- corriger le problème de locale d'Ubuntu 13.04 si vous voyez des warning suite à la commande précédente

modifier `/etc/default/locale` avec le contenu :

```
#  File generated by update-locale
LANGUAGE=en_US:en
LANG=en_US.UTF-8
LC_CTYPE=en_US.UTF-8
LC_ALL=en_US.UTF-8
```

Puis se relogguer.

- générer la clé SSH de root (`ssh-keygen -t rsa`), et l'ajouter aux ["Deploy keys" de myclabs/Inventory](https://github.com/myclabs/Inventory/settings/keys)

Une fois fait, on peut exécuter le script.

Après l'exécution du script, créer les utilisateurs avec `adduser`, `groupadd admin` (`admin` est un groupe automatiquement autorisé à faire `sudo`), `usermod -a -G admin someuser` puis ajouter dans `/etc/sudoers`:

```
# Allow jenkins to deploy
jenkins ALL = NOPASSWD: /usr/local/bin/deploy
```

Créer l'utilisateur jenkins (`adduser jenkins`) et permettre son login via clé SSH en ajoutant la clé publique à `/home/jenkins/.ssh/authorized_keys`.

Puis désactiver le login SSH root et changer le port SSH pour 4269 (`/etc/ssh/sshd_config`).

Pour configurer l'heure : `sudo dpkg-reconfigure tzdata` puis ajouter dans la crontab root (`sudo crontab -e`) :

    @hourly /etc/network/if-up.d/ntpdate ntp.ubuntu.com

Il se peut que phpMyAdmin s'affiche mal, dans ce cas :

    dpkg-reconfigure phpmyadmin

Pour l'envoi de mail :

    sudo apt-get install exim4

Configuration dans `/etc/exim4/update-exim4.conf.conf` :

    dc_eximconfig_configtype='internet'

Puis redémarrer Exim 4: `sudo /etc/init.d/exim4 restart`.

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

**Attention** : le script demandera à un moment de s'identifier pour GitHub (pour cloner `myclabs/deploy`).
Utiliser ses propres identifiants : ils ne sont pas sauvegardés.

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
