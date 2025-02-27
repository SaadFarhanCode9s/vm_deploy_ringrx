#
# Cookbook Name:: ringrx_synapse
# Recipe:: patroni
#
# Copyright 2025, RingRX
#
# All rights reserved - Do Not Redistribute
#
##############################################################################
#### Patroni - Template for HA PostgreSQL 
##############################################################################



###############################################################################
#### Update Python and PIP
###############################################################################


bash 'update and upgrade package cache' do
    code "apt update && upgrade"
    returns [0, 1, 100]
end

bash 'install python3 testresources' do
    code "apt install python3-testresources -y"
    returns [0, 1, 100]
end


bash 'upgrade pip' do
    code "python3 -m pip install --upgrade pip"
    returns [0, 1, 100]
end

bash 'upgrade setup tools' do
    code "python3 -m pip install --upgrade setuptools"
    returns [0, 1, 100]
end



###############################################################################
#### Install Patroni
###############################################################################
bash 'install patroni' do
    code "python3 -m pip install patroni python-etcd psycopg2"
    returns [0, 1, 100]
end



###############################################################################
####Create Directories and Swap Permissions
###############################################################################


#Patroni Configuration directory
directory "/etc/patroni" do
    recursive true
    owner 'postgres'
    group 'postgres'
    mode '0750'
    action :create
end


#Patroni Logs directory i.e. /var/log/patroni
directory "#{node['rxsynapse_attributes']['patroni']['log_dir']}" do
    recursive true
    owner 'postgres'
    group 'postgres'
    mode '0750'
    action :create
end



# Make sure the postgresql log directory "{{ postgresql_log_dir }}" exists
directory "#{node['rxsynapse_attributes']['pgsql']['postgresql_log_dir']}" do
    recursive true
    owner 'postgres'
    group 'postgres'
    mode '0700'
    action :create
end


###############################################################################
####Patroni Configuration
###############################################################################

etcd_nodes_list = []

node['rxsynapse_attributes']['servers'].each do |server| 
    etcd_nodes_list.push "#{server['ipaddress']}:#{node['rxsynapse_attributes']['etcd']['host_port']}"
end

#Update conf file "/etc/patroni/patroni.yml"
template "/etc/patroni/patroni.yml" do
    source 'patroni/patroni.yml.erb'
    owner 'postgres'
    group 'postgres'
    mode '0640'
    action :create
    variables(
        :etcd_nodes_list  => etcd_nodes_list
    )
end


###############################################################################
####Patroni Service Configuration
###############################################################################

template "/etc/systemd/system/patroni.service" do
    source "patroni/patroni.service.erb"
    owner 'root'
    group 'root'
    mode '0644'
    action :create
end


service 'patroni' do
    supports :status => true, :restart => true, :reload => true
    action [ :enable, :start ]
end