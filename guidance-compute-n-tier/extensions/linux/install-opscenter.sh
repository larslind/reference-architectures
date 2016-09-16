#!/usr/bin/env bash

cloud_type="azure"
seed_node_name=$1

echo "Input to node.sh is:"
echo cloud_type $cloud_type
echo seed_node_name $seed_node_name

seed_node_dns_name="$seed_node_name.cloudapp.azure.com"

echo "Calling opscenter.sh with the settings:"
echo cloud_type $cloud_type
echo seed_node_dns_name $seed_node_dns_name

apt-get -y install unzip

wget https://github.com/DSPN/install-datastax-ubuntu/archive/5.0.1-5.zip
unzip 5.0.1-5.zip
cd install-datastax-ubuntu-5.0.1-5/bin

#wget https://github.com/DSPN/install-datastax-ubuntu/archive/master.zip
#unzip master.zip
#cd install-datastax-ubuntu-master/bin

./opscenter.sh $cloud_type $seed_node_dns_name