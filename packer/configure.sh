#!/bin/sh
sudo mv /tmp/disable-transparent-hugepages /etc/init.d/disable-transparent-hugepages
sudo chmod 755 /etc/init.d/disable-transparent-hugepages
sudo mkdir -p /data/db
sudo chown -R mongod:mongod /data/db
sudo mv /tmp/mongod /etc/logrotate.d/mongodb
sudo chown root:root /etc/logrotate.d/mongodb
sudo mkdir -p /opt/mongod
cd /opt/mongod
sudo openssl rand -base64 741 > keyfile
sudo chown mongod:mongod /opt/mongod/keyfile
sudo chmod 600 /opt/mongod/keyfile


