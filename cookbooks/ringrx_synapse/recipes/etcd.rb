#
# Cookbook Name:: ringrx_synapse
# Recipe:: ETCD
#
# Copyright 2025, RingRX
#
# All rights reserved - Do Not Redistribute
#
##############################################################################
#### ETCD - Template for HA PostgreSQL 
##############################################################################




###############################################################################
#### Download and Install ETCD
###############################################################################

bash 'download etcd' do
    code "curl -L #{node['rxsynapse_attributes']['etcd']['etcd_download_url']}/#{node['rxsynapse_attributes']['etcd']['etcd_version']}/etcd-#{node['rxsynapse_attributes']['etcd']['etcd_version']}-linux-amd64.tar.gz -o /tmp/etcd-#{node['rxsynapse_attributes']['etcd']['etcd_version']}-linux-amd64.tar.gz"
    retries 3
    returns [0, 1, 2]
end

bash 'extract etcd package' do
    code "tar xzvf /tmp/etcd-#{node['rxsynapse_attributes']['etcd']['etcd_version']}-linux-amd64.tar.gz -C /tmp"
end


bash 'move etcd directory' do
    code "mv /tmp/etcd-#{node['rxsynapse_attributes']['etcd']['etcd_version']}-linux-amd64/etcd /usr/local/bin/"
end
bash 'move etcdctl directory' do
    code "mv /tmp/etcd-#{node['rxsynapse_attributes']['etcd']['etcd_version']}-linux-amd64/etcdctl /usr/local/bin/"
end
bash 'move etcdutl directory' do
    code "mv /tmp/etcd-#{node['rxsynapse_attributes']['etcd']['etcd_version']}-linux-amd64/etcdutl /usr/local/bin/"
end


###############################################################################
#### Swap Permissions
###############################################################################


bash 'change etcd folder permissions' do
	code "chown root:root /usr/local/bin/etcd"
end

bash 'swap etcdctl folder permissions' do
	code "chown root:root /usr/local/bin/etcdctl"
end

bash 'swap etcdutl folder permissions' do
	code "chown root:root /usr/local/bin/etcdutl"
end


###############################################################################
#### Remove tmp Folder
###############################################################################

bash 'remove tmp folder' do
	code "rm -rf /tmp/etcd-#{node['rxsynapse_attributes']['etcd']['etcd_version']}-linux-amd64*"
end

#remove if not required
bash 'echo etcd version' do
    code 'etcd --version'
end


###############################################################################
#### ETCD user and directories
###############################################################################

if !Dir.exist?("/etc/etcd")
    bash 'add etcd user' do
        code 'useradd --system --no-create-home etcd'
    end
end


#Create etcd conf directory
directory "/etc/etcd" do
    recursive true
    owner 'etcd'
    group 'etcd'
    mode '0777'
    action :create
end

#Create etcd data directory
directory "#{node['rxsynapse_attributes']['etcd']['etcd_data_dir']}" do
    recursive true
    owner 'etcd'
    group 'etcd'
    mode '0700'
    action :create
end


###############################################################################
#### ETCD Configuration
###############################################################################

etcd_nodes_list = []

node['rxsynapse_attributes']['servers'].each do |server| 
    etcd_nodes_list.push "#{server['node_name']}=http://#{server['ipaddress']}:#{node['rxsynapse_attributes']['etcd']['cluster_port']}"
end

template "/etc/etcd/etcd.conf.yml" do
    source 'etcd/etcd.yml.erb'
    action :create
    variables(
        :etcd_nodes_list  => etcd_nodes_list
    )
end


###############################################################################
#### ETCD Service
###############################################################################

template "/usr/lib/systemd/system/etcd.service" do
    source "etcd/etcd.service.erb"
    owner 'root'
    group 'root'
    mode '0644'
    action :create
    notifies :restart, 'service[etcd.service]', :delayed
end

service 'etcd.service' do
    supports :status => true, :restart => true, :reload => true
    action [ :enable, :start ]
end
