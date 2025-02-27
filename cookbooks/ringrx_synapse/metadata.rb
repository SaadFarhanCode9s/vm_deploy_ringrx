name             'ringrx_synapse'
maintainer       'RingRx LLC'
maintainer_email 'sfarhan@ringrx.com'
license          'All rights reserved'
description      'Installs/Configures ringrx_synapse'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

recipe "ringrx_synapse::hosts", "Ringrx Setup Replication Nodes"
recipe "ringrx_synapse::confd", "Ringrx Setup Confd"
recipe "ringrx_synapse::haproxy", "Ringrx Setup HAproxy"
recipe "ringrx_synapse::etcd", "Ringrx Setup ETCD"
recipe "ringrx_synapse::postgres", "Ringrx Setup PostgreSQL"
recipe "ringrx_synapse::patroni", "Ringrx Setup Patroni"
recipe "ringrx_synapse::redis", "Ringrx Setup Redis and Redis Sentinel"
recipe "ringrx_synapse::synapse", "Ringrx Setup Matrix Synapse"
recipe "ringrx_synapse::finalize", "Ringrx finalize node setup (Usually involves services or node restart)"
