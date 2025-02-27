#
# Cookbook Name:: ringrx_synapse
# Recipe:: Finalize
#
# Copyright 2025, RingRX
#
# All rights reserved - Do Not Redistribute
#
##################################################################################
#### Ringrx Finalize
###################################################################################



#Clear data directory for patroni
# i_am_master = false

# node['rxsynapse_attributes']['servers'].each do |server|
#     if server['ipaddress'] == node['rxsynapse_attributes']['ipaddress'] && server['patroni_master'] == true
#         i_am_master = true
#     end 
# end

# if @i_am_master
#     bash 'patroni data directory remove' do
#         code "rm -rf /var/lib/postgresql/12/main"
#         returns [0, 1, 100]
#     end
# end 

#Restart Patroni Cluster
# /usr/bin/patronictl -c /etc/patroni/patroni.yml restart postgres_cluster

#Reboot the Machine after Delay. This gives us a good chance for ETCD and Patroni to look for fellow nodes/clusters
bash 'reboot node' do
    # code "sleep 150 &&  reboot"
    code "reboot"
    returns [0, 1, 100]
end