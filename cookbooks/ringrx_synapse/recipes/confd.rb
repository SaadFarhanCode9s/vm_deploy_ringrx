#
# Cookbook Name:: ringrx_synapse
# Recipe:: Confd
#
# Copyright 2025, RingRX
#
# All rights reserved - Do Not Redistribute
#
##################################################################################################################
#### Confd - Sync configuration files by polling etcd & Reloading applications to pick up new config file changes
##################################################################################################################





###############################################################################
#### Create Confd Directories
###############################################################################


# Create confd download directory
directory "/usr/local/bin/confd" do
  recursive true
  owner 'root'
  group 'root'
  mode '0777'
  action :create
end

# Create conf.d directory
directory "/etc/confd/conf.d" do
  recursive true
  owner 'root'
  group 'root'
  mode '0777'
  action :create
end


# Create templates directory
directory "/etc/confd/templates" do
  recursive true
  owner 'root'
  group 'root'
  mode '0777'
  action :create
end


###############################################################################
#### Download and Install Confd
###############################################################################

# download confd package from repo
bash 'Download confd binary file to /usr/local/bin/' do
  code "curl -L #{node['rxsynapse_attributes']['confd']['confd_package_repo']} -o /usr/local/bin/confd/#{node['rxsynapse_attributes']['confd']['confd_package_name']}"
  retries 3
  returns [0, 1, 2]
end

###############################################################################
#### Swap Permissions
###############################################################################


bash 'swap folder permissions' do
  code "chmod +x /usr/local/bin/confd"
end


###############################################################################
#### Export path
###############################################################################

bash 'export confd path' do
  code "export PATH='$PATH:/usr/local/bin/confd'"
end


###############################################################################
#### Templates
###############################################################################

template "/etc/confd/confd.toml" do
  source "confd/confd.toml.erb"
  action :create
end

template "/etc/confd/conf.d/haproxy.toml" do
  source "confd/haproxy.toml.erb"
  action :create
end

template "/etc/confd/templates/haproxy.tmpl" do
  source "confd/haproxy.tmpl.erb"
  action :create
end




###############################################################################
#### Service
###############################################################################

template "/etc/systemd/system/confd.service" do
  source "confd/confd.service.erb"
  owner 'root'
  group 'root'
  mode '0644'
  action :create
end

service 'etcd.service' do
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
end
