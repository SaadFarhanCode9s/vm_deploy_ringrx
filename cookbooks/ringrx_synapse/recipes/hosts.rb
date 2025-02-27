#
# Cookbook Name:: ringrx_synapse
# Recipe:: hosts
#
# Copyright 2025, RingRX
#
# All rights reserved - Do Not Redistribute
#
##################################################################################
####Ringrx_setup replication hosts
####This will manage replication nodes for the sake of discovery by sub-components
###################################################################################

bash 'update package cache' do
    code "apt-get update"
    returns [0, 1, 100]
end


#hosts template for cloud based machines

# template "/etc/cloud/templates/hosts.debian.tmpl" do
#     source 'hosts/hosts.debian.tmpl.erb'
#     owner 'root'
#     group 'root'
#     mode '0644'
#     action :create
# end


template "/etc/hosts" do
    source 'hosts/hosts.erb'
    owner 'root'
    group 'root'
    mode '0644'
    action :create
end