#! /bin/sh

yum -y update
cat > /etc/yum.repos.d/mongodb-org-4.0.repo <<EOL
[mongodb-org-4.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/amazon/2013.03/mongodb-org/4.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-4.0.asc
EOL
yum -y install mongodb-org

