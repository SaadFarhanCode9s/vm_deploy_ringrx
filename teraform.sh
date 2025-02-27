#!/bin/bash

USER=$(whoami)
LOGGER='logger -ist host_setup.sh: '

# Check the script is being run by root, or die.
ROOT_UID=0
if [ "$UID" -ne "$ROOT_UID" ]
        then
        echo "We are not running as root." | $LOGGER
        exit 2
fi

#grep -qxF 'deb http://http.debian.net/debian buster-backports main' /etc/apt/sources.list || echo 'deb http://http.debian.net/debian buster-backports main' >> /etc/apt/sources.list 

apt-get install -y apt-transport-https gnupg2
wget -qO - https://packages.chef.io/chef.asc | apt-key add -

grep -qxF 'deb https://packages.chef.io/repos/apt/current bullseye main' /etc/apt/sources.list || echo 'deb https://packages.chef.io/repos/apt/current bullseye main' >> /etc/apt/sources.list 

apt-get update

echo "Installing initial packages" | $LOGGER
apt-get install \
     git \
     chef \
     curl \
     software-properties-common

echo "Cleaning up chef artifacts for clean run"
rm -rf ./local-mode-cache
rm -rf ../nodes

cd /root/vm_deploy_ringrx/ && chef-solo --force-logger -c solo.rb

