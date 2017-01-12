FROM mariadb:10.1

RUN set -x && \
    apt-get update && apt-get install -y --no-install-recommends ca-certificates wget && \
    rm -rf /var/lib/apt/lists/* && \
    \
    wget -O /usr/local/bin/peer-finder https://storage.googleapis.com/kubernetes-release/pets/peer-finder && \
    chmod +x /usr/local/bin/peer-finder && \
    \
    apt-get purge -y --auto-remove ca-certificates wget

ADD galera.cnf docker-entrypoint.sh on-start.sh galera_recovery.sh /opt/galera/

RUN set -x && \
    cd /opt/galera && \
    chmod +x docker-entrypoint.sh on-start.sh galera_recovery.sh && \
    mv docker-entrypoint.sh /usr/local/bin

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["mysqld"]
