#!/bin/bash

# This scripts prepares docker on CentOS 7 machine

# Docker installation
yum install -y yum-utils device-mapper-persistent-data lvm2

yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo

yum makecache fast

yum install -y docker-ce

# Open ports
#firewall-cmd --add-port=2376/tcp --permanent
#firewall-cmd --add-port=2377/tcp --permanent
#firewall-cmd --add-port=7946/tcp --permanent
#firewall-cmd --add-port=7946/udp --permanent
#firewall-cmd --add-port=4789/udp --permanent

#firewall-cmd --reload

systemctl start docker
