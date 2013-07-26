# Configuration Puppet pour configurer un serveur

## The setup includes:

* box:       precise64 (Ubuntu 12.10)
* webserver: apache
* database:  mysql
* PHP:       PHP 5.4

## Tester la configuration en local dans vagrant

Pour démarrer la machine virtuelle et lancer l'installation :

    $ vagrant up

Accès à la machine virtuelle :

    $ vagrant ssh

## Déployer sur un serveur

```
$ ssh monserver
$ git clone https://github.com/myclabs/servers.git
$ cd servers/
$ puppet --verbose --modulepath modules manifests/default.pp
```

## TODO

- sortir la config phpMyAdmin de la config vagrant
- script qui lance puppet plus simplement
