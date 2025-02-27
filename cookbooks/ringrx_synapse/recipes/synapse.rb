#
# Cookbook Name:: ringrx_synapse
# Recipe:: Matrix Synapse
#
# Copyright 2025, RingRX
#
# All rights reserved - Do Not Redistribute
#
##############################################################################
#### Matrix Synapse - Template for HA PostgreSQL 
##############################################################################



###############################################################################
#### Install Matrix Synapse
###############################################################################


bash 'install dependencies' do
    code "apt install lsb-release wget apt-transport-https -y"
    returns [0, 1, 100]
end


if !File.exist?("/usr/share/keyrings/matrix-org-archive-keyring.gpg")
    bash 'Add synapse repo key' do
        code "wget -O /usr/share/keyrings/matrix-org-archive-keyring.gpg https://packages.matrix.org/debian/matrix-org-archive-keyring.gpg"
        returns [0]
        retries 5
    end
end


bash 'echo synapse key' do
    code "echo deb [signed-by=/usr/share/keyrings/matrix-org-archive-keyring.gpg] https://packages.matrix.org/debian/ $(lsb_release -cs) main | sudo tee /etc/apt/sources.list.d/matrix-org.list"
end


bash 'update package cache' do
    code "apt-get update"
    returns [0, 1, 100]
end







###############################################################################
#### Synapse Configuration
###############################################################################

#Set Debian Conf value before proceeding with installation
bash 'Setting Up Homeserver URL' do
    code "echo matrix-synapse-py3 matrix-synapse/server-name string #{node['rxsynapse_attributes']['matrix_fqdn']} | debconf-set-selections"
    returns [0, 1, 100]
    retries 1 #Check if retries are required
end



#Create Required Directories
directory "/etc/matrix-synapse/conf.d" do
    recursive true
    owner 'root'
    group 'root'
    mode '0777'
    action :create
end

#Server name Yaml
template "/etc/matrix-synapse/conf.d/server_name.yaml" do
    source 'matrix_synapse/server_name.yml.erb'
    owner 'root'
    group 'root'
    mode '0644'
    action :create
end
    

template "/etc/matrix-synapse/conf.d/homeserver.yaml" do
    source 'matrix_synapse/homeserver.yml.erb'
    owner 'root'
    group 'root'
    mode '0644'
    action :create
end



###############################################################################
#### Synapse Server Installation
###############################################################################

#Perform Non-Interactive Installation
bash 'install matrix synapse' do
    code "DEBIAN_FRONTEND=noninteractive apt install -y matrix-synapse-py3"
    returns [0, 1, 100]
    retries 5 #Check if retries are required
end


###############################################################################
#### Synapse Service Configuration
###############################################################################

template "/etc/systemd/system/matrix-synapse.service" do
    source "matrix_synapse/matrix-synapse.service.erb"
    owner 'root'
    group 'root'
    mode '0644'
    action :create
    # notifies :restart, 'service[matrix-synapse]', :delayed
end


template "/etc/systemd/system/matrix-synapse.target" do
    source "matrix_synapse/matrix-synapse.target.erb"
    owner 'root'
    group 'root'
    mode '0644'
    action :create
    # notifies :restart, 'service[matrix-synapse.target]', :delayed
end

###############################################################################
#### Synapse Worker Configuration
###############################################################################

# if !File.exist?("/etc/matrix-synapse/workers/")
#     bash 'create directory for worker' do
#         code "mkdir /etc/matrix-synapse/workers"
#     end
# end

#Create Workers Directory
directory "/etc/matrix-synapse/workers/" do
    recursive true
    owner 'root'
    group 'root'
    mode '0700'
    action :create
end



#Create a worker configuration for each worker defined in the node
%w{node['rxsynapse_attributes']['matrix_synapse']['workers']}.each do |worker|
    worker_name = worker['name']
    worker_port = worker['port']
    template "/etc/matrix-synapse/workers/worker.matrix-synapse-worker-#{worker_name}.yaml" do
        source 'matrix_synapse/matrix-synapse-worker.yaml.erb'
        owner 'root'
        group 'root'
        mode '0644'
        action :create
        variables(
            :worker_name  => worker_name,
            :worker_port => worker_port
        )
    end    
end

###############################################################################
#### Synapse Worker Service Configuration
###############################################################################

%w{node['rxsynapse_attributes']['matrix_synapse']['workers']}.each do |worker|
    worker_name = worker['name']
    template "/etc/systemd/system/matrix-synapse-worker@matrix-synapse-worker-#{worker_name}.service" do
        source "matrix_synapse/matrix-synapse-worker.service.erb"
        owner 'root'
        group 'root'
        mode '0644'
        action :create
        notifies :restart, 'service[matrix-synapse.target]', :delayed
        variables(
            :worker_name  => worker_name
        )
    end 
end



###############################################################################
#### Synapse module Configuration
###############################################################################

template "/opt/venvs/matrix-synapse/lib/python3.9/site-packages/auth_callback.py" do
    source 'matrix_synapse/auth_callback.py.erb'
    owner 'root'
    group 'root'
    mode '0644'
    action :create
end



#Enable and start the master process.
service 'matrix-synapse.target' do
    supports :status => true, :restart => true, :reload => true
    action [ :enable, :start ]
end


# template "#{node['rxsynapse_attributes']['scriptsdir']}/synapse_database.sh" do
#     source 'matrix_synapse/synapse_database.sh.erb'
#     owner 'root'
#     group 'root'
#     mode '0777'
#     action :create
# end

#Cron Job For Synapse DB and user creation. This job will look for successful postgres connection via patroni and perform the actions.
# cron 'synapse_db_user_setup' do
#     minute '5'
#     user 'root'
#     command "bash -lc #{node['rxsynapse_attributes']['scriptsdir']}/synapse_database.sh"
#     only_if { ::File.exist?('/home/jboss') }
# end 

# if [ "$( sudo -i -u postgres psql -XtAc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'" )" = '1' ]


# cron 'ganglia_tomcat_thread_max' do
#     command "/usr/bin/gmetric
#       -n 'tomcat threads max'
#       -t uint32
#       -v '/usr/local/bin/tomcat-stat --thread-max'"
#     only_if { ::File.exist?('/home/jboss') }
#   end

#Starting the master process
# service 'matrix-synapse.target' do
#     supports :status => true, :restart => true, :reload => true
#     action [ :start ]
# end