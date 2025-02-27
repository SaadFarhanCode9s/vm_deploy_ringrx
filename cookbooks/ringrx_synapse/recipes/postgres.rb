#
# Cookbook Name:: ringrx_synapse
# Recipe:: PostgreSQL
#
# Copyright 2025, RingRX
#
# All rights reserved - Do Not Redistribute
#
##############################################################################
#### PostgreSQL Meta-package
##############################################################################


#Defining PostgreSQL variables
postgresql_version = node['rxsynapse_attributes']['pgsql']['version']


if !File.exist?("/etc/apt/trusted.gpg.d/postgresql.gpg")
    bash 'Add postgresql repo key' do
        code "curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc|sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg"
        returns [0]
        retries 5
    end
end


bash 'postgresql-repo' do
    code "echo deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main ./ > /etc/apt/sources.list.d/pgdg.list"
end


bash 'update package cache' do
    code "apt-get update"
    returns [0, 1, 100]
end


bash 'install postgresql ' do
    code "apt install -y postgresql-#{postgresql_version} postgresql-client-#{postgresql_version} postgresql-contrib-#{postgresql_version} postgresql-server-dev-#{postgresql_version} postgresql-#{postgresql_version}-dbgsym"
    returns [0, 1]
end



if !File.exist?("/usr/sbin/clusterdb")
    bash 'postgres symbolic linking' do
        code "ln -s /usr/lib/postgresql/#{postgresql_version}/bin/* /usr/sbin/"
    end
end



##############################################################################
#### Configuration Files
##############################################################################

# for Debian based distros only
# patroni bootstrap failure is possible if the PostgreSQL config files are missing

#Prepare PostgreSQL | make sure PostgreSQL config directory exists
directory "#{node['rxsynapse_attributes']['patroni']['config_dir']}" do
    recursive true
    owner 'postgres'
    group 'postgres'
    mode '0700'
    action :create
end



##############################################################################
#### Alter Postgres pg_hba.conf
##############################################################################

template "#{node['rxsynapse_attributes']['patroni']['config_dir']}/pg_hba.conf" do
    source 'postgres/pg_hba.conf.erb'
    owner 'postgres'
    group 'postgres'
    mode '0640'
    action :create
end


##############################################################################
#### Configure a password file
##############################################################################

template "#{node['rxsynapse_attributes']['pgsql']['postgresql_home_dir']}/.pgpass" do
    source 'postgres/pgpass.erb'
    owner 'postgres'
    group 'postgres'
    mode '0600'
    action :create
end


##############################################################################
#### Start Postgres Service
##############################################################################

#We will stop patroni before starting postgres.
if File.exist?("/etc/systemd/system/patroni.service") #Check if patroni service file is already created
    service "patroni" do 
        action :stop
    end
end

# #By default, postgres service will be disabled for it to be handled by patroni
service 'postgresql' do
    supports :status => true, :restart => true, :reload => true
    action [ :disable, :start ]
end


##############################################################################
#### CREATE REPLICATOR AND SUPER USER FOR PATRONI
##############################################################################

template "#{node['rxsynapse_attributes']['scriptsdir']}/patroni_postgres_users.sh" do
    source 'postgres/patroni_postgres_users.sh.erb'
    owner 'root'
    group 'root'
    mode '0777'
    action :create
end

#Execute the bash script
bash 'matrix synapse database and users creation' do
    user 'root'
    code "bash #{node['rxsynapse_attributes']['scriptsdir']}/patroni_postgres_users.sh"
    returns [0, 1, 100]
end

##############################################################################
#### Matrix Synapse Database Setup
##############################################################################

## Default, creating DB and users on master node ONLY

# @i_am_master = false

# node['rxsynapse_attributes']['servers'].each do |server|
#     if server['ipaddress'] == node['rxsynapse_attributes']['ipaddress']
#         if server['patroni_master'] == true
#             @i_am_master = true
#         end         
#     end    
# end




# if @i_am_master
#     bash 'echo if node is Patroni master' do
#         code "echo Patroni Master TRUE"
#         returns [0, 1]
#     end
# else
#     bash 'echo if node is Patroni master' do
#         code "echo Patroni Master FALSE"
#         returns [0, 1]
#     end
#         # Create bash script to check if synapse DB already exists or create one if not.
#         # template "/tmp/synapse-postgres.sh" do
#         #     source 'postgres/synapse_database.sh.erb'
#         #     owner 'root'
#         #     group 'root'
#         #     mode '0777'
#         #     action :create
#         # end
    
#         #Execute the bash script
#         # bash 'matrix synapse database creation' do
#         #     user 'root'
#         #     code "bash /tmp/synapse-postgres.sh"
#         #     returns [0, 1, 100]
#         # end
# end


#Once we have created postgres user and database, we will disable and stop the service for it will be handled by patroni
service 'postgresql' do
    supports :status => true, :restart => true, :reload => true
    action [ :stop ]
end


# # #We will start patroni after stopping postgres.
if File.exist?("/etc/systemd/system/patroni.service") #Check if patroni service file is already created
    service "patroni" do 
        action :start
    end
end