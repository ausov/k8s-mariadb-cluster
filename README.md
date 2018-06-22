# MariaDB Galera on Kubernetes

Example of Docker image of MariaDB Galera cluster to be used in Kubernetes StatefulSet 
definition.

Based on official [MariaDB image][mariadb-image].
Uses [peer-finder.go][peer-finder] util from Kibernetes contrib.
Depending on service peers updates `wsrep_*` settings in a Galera config file.

## Settings

See: [MariaDB image][mariadb-image] documentation

Additional variables:

* `POD_NAMESPACE` - The namespace, e.g. `default`
* `GALERA_CONF` - The location of galera config file, e.g. `/etc/mysql/conf.d/galera.cnf`
* `GALERA_SERVICE` - The service name to lookup, e.g. `galera`

[peer-finder]: https://github.com/kubernetes/contrib/tree/master/peer-finder
[mariadb-image]: https://hub.docker.com/_/mariadb/
