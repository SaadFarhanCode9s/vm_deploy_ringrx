#
# Cookbook Name:: ringrx_synapse
# Recipe:: default
#
# Copyright 2025, RingRX
#
# All rights reserved - Do Not Redistribute
#
###############################################################################
####This is a meta-recipe for setting up the synapse HA server
###############################################################################


package 'wget' do
        action :install
end

package 'nano' do
        action :install
end

package 'git' do
        action :install
end


bash 'update package cache' do
        code "apt-get update"
        returns [0, 1, 100]
end


#Install required system packages
bash 'install system required packages' do
        code "apt -y install sudo less curl zstd tar unzip moreutils dnsutils acl iptables jq gcc vim gnupg2 net-tools"
        returns [0, 1, 100]
end


bash 'install software-properties-common' do
        code "apt -y install software-properties-common"
        returns [0, 1, 100]
end

#Python
bash 'install python and packages' do
        code "apt -y install python3 python3-dev python3-psycopg2 python3-setuptools python3-pip libpq-dev"
        returns [0, 1, 100]
end



#1. First setup hosts for fellow nodes discovery.
include_recipe 'ringrx_synapse::hosts'

#2. Setup Redis and Redis Sentinel for Failover and HA
include_recipe 'ringrx_synapse::redis'

#3. Setup PostgreSQL and create matrix synapse DB and user
include_recipe 'ringrx_synapse::postgres'

#4. Setup ETCD for failover and master/replica configuration
include_recipe 'ringrx_synapse::etcd'

#5. Setup Patroni For PostgreSQL HA and Failover
include_recipe 'ringrx_synapse::patroni'

#6. Setup Confd For PostgreSQL HA and Failover
include_recipe 'ringrx_synapse::confd'

#7. Setup HAproxy with synapse and postgresql configuration
include_recipe 'ringrx_synapse::haproxy'

#8. Setup Matrix synapse, install ringRX module and workers
# include_recipe 'ringrx_synapse::synapse'



#Finalize the setup - usually involves restarting services in order or rebooting the machine
# include_recipe 'ringrx_synapse::finalize'


#TODO:
#Update apt keys to gpg keys*

# -> a model i use for galera is a core "cluster" of N nodes is set in the node.json file

# -> this will work fine since i dont expect to need to do elastic scaling

# -> the idea is we should be able to destroy / replace any node with a fresh chef rebuild at will. This will include joining PG to replication  