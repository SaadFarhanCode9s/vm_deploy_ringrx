#
# Cookbook Name:: ringrx_synapse
# Recipe:: HAproxy
#
# Copyright 2025, RingRX
#
# All rights reserved - Do Not Redistribute
#
##############################################################################
#### HAproxy - Template for HA PostgreSQL 
##############################################################################




###############################################################################
#### Download and Install HAproxy
###############################################################################

if !File.exist?("/usr/share/keyrings/haproxy.debian.net.gpg")
    bash 'Add haproxy repo key' do
        code "curl https://haproxy.debian.net/bernat.debian.org.gpg | gpg --dearmor > /usr/share/keyrings/haproxy.debian.net.gpg"
        returns [0]
        retries 5
    end
end


bash 'echo haproxy repo' do
    code "echo deb '[signed-by=/usr/share/keyrings/haproxy.debian.net.gpg]' http://haproxy.debian.net bullseye-backports-3.0 main > /etc/apt/sources.list.d/haproxy.list"
end


bash 'update package cache' do
    code "apt-get update"
    returns [0, 1, 100]
end

bash 'install haproxy' do
    code "apt-get install haproxy -y"
    returns [0, 1, 100]
end


###############################################################################
#### HAproxy Configuration
###############################################################################

template "/etc/haproxy/haproxy.cfg" do
    source 'haproxy/haproxy.cfg.erb'
    owner 'root'
    group 'root'
    mode '0644'
    action :create
end


template "/etc/systemd/system/haproxy.service" do
    source "haproxy/haproxy.service.erb"
    owner 'root'
    group 'root'
    mode '0644'
    action :create
end


service 'haproxy' do
    supports :status => true, :restart => true, :reload => true
    action [ :enable, :start ]
end























