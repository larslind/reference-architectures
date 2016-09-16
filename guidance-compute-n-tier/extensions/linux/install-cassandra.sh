#!/usr/bin/env bash

cloud_type="azure"
seed_vm_name=$1
opscenter_vm_name=$2
data_center_name=$3

echo "Input to install-cassandra.sh is:"
echo cloud_type $cloud_type
echo seed_vm_name $seed_vm_name
echo opscenter_vm_name $opscenter_vm_name
echo data_center_name $data_center_name

seed_node_dns_name="$seed_vm_name.cloudapp.azure.com"
opscenter_dns_name="$opscenter_vm_name.cloudapp.azure.com"

echo "Calling dse.sh with the settings:"
echo cloud_type $cloud_type
echo seed_node_dns_name $seed_node_dns_name
echo data_center_name $data_center_name
echo opscenter_dns_name $opscenter_dns_name

apt-get -y install unzip

wget https://github.com/DSPN/install-datastax-ubuntu/archive/5.0.1-5.zip
unzip 5.0.1-5.zip
cd install-datastax-ubuntu-5.0.1-5/bin

#wget https://github.com/DSPN/install-datastax-ubuntu/archive/master.zip
#unzip master.zip
#cd install-datastax-ubuntu-master/bin

./dse.sh $cloud_type $seed_node_dns_name $data_center_name $opscenter_dns_name