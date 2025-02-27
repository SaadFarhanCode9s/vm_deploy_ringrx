#
# Cookbook Name:: ringrx_synapse
# Recipe:: Redis
#
# Copyright 2025, RingRX
#
# All rights reserved - Do Not Redistribute
#
##############################################################################
#### Redis - Template for HA PostgreSQL 
##############################################################################




###############################################################################
#### Download and Install Redis + Redis Sentinel
###############################################################################

bash 'sysctl max conns' do
    code 'sysctl -w net.core.somaxconn=65535'
end

bash 'sysctl max conns' do
    code 'sysctl -w vm.overcommit_memory=1'
end

bash 'Add the repository to the apt index' do
    code "add-apt-repository ppa:redislabs/redis"
end

bash 'update package cache' do
    code "apt-get -y update"
    returns [0, 1, 100]
end

bash 'install redis sentinel and net-tools' do
    code "apt-get -y install redis redis-sentinel net-tools"
    returns [0, 1, 100]
end



###############################################################################
#### Redis and Sentinel Configuration
###############################################################################


i_am_master = false
master_ipaddress = false
quorum = 1

node['rxsynapse_attributes']['servers'].each do |server|

    if server['ipaddress'] == node['rxsynapse_attributes']['ipaddress']
        i_am_master = true
    end

    if server['redis_master'] == true
        master_ipaddress = server['ipaddress']
    end 
end

if node['rxsynapse_attributes']['servers'].count > 2
    quorum = (((node['rxsynapse_attributes']['servers'].count)/2))
else
    quorum = 1
end 


#stopping services
service 'redis' do
	supports :status => true, :restart => true, :reload => true, :stop => true
	action [ :stop ]
end

service 'redis-sentinel stop' do
	supports :status => true, :restart => true, :reload => true, :stop => true
	action [ :stop ]
end


template "/etc/redis/redis.conf" do
        source "redis/redis.conf.erb"
        owner 'redis'
        group 'redis'
        mode '0644'
        action :create
        notifies :restart, 'service[redis]', :delayed
        variables(
            :i_am_master  => i_am_master,
            :master_ipaddress => master_ipaddress
        )
end



template "/etc/redis/sentinel.conf" do
        source "redis/redis-sentinel.conf.erb"
	    owner 'redis'
        group 'redis'
        mode '0644'
	    action :create
        variables(
            :i_am_master  => i_am_master,
            :master_ipaddress => master_ipaddress,
            :quorum => quorum
        )
end

service 'redis-sentinel' do
        supports :status => true, :restart => true, :reload => true
end




###############################################################################
#### Redis and Sentinel Starting Services
###############################################################################

service 'redis' do
	supports :status => true, :restart => true, :reload => true, :stop => true
	action [ :start ]

end

service 'redis-sentinel' do
	supports :status => true, :restart => true, :reload => true, :stop => true
	action [ :start ]
end



















