#! /bin/sh 
cat >> /etc/security/limits.conf <<EOL 
* soft nofile 64000
* hard nofile 64000
* soft nproc 32000
* hard nproc 32000
EOL

cat >> /etc/security/limits.d/90-nproc.conf <<EOL 
* soft nproc 32000
* hard nproc 32000
EOL
