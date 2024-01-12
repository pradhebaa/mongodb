# Install mongo exportor for Prometheus
mkdir -p /opt/exporters
cd /opt/exporters
wget https://github.com/dcu/mongodb_exporter/releases/download/v1.0.0/mongodb_exporter-linux-amd64 && wget https://github.com/prometheus/node_exporter/releases/download/v0.18.1/node_exporter-0.18.1.linux-amd64.tar.gz
tar xvzf node_exporter-0.18.1.linux-amd64.tar.gz
useradd -rs /bin/false prometheus
useradd -rs /bin/false node_exporter
mv /opt/exporters/mongodb_exporter-linux-amd64 /usr/local/bin/mongodb_exporter && mv /opt/exporters/node_exporter-0.18.1.linux-amd64/node_exporter /usr/local/bin/node_exporter
chmod 755 /usr/local/bin/mongodb_exporter && chmod 755 /usr/local/bin/node_exporter
cat > /lib/systemd/system/mongodb_exporter.service <<EOL
[Unit]
Description=MongoDB Exporter

[Service]
Type=simple
Restart=always
ExecStart=/usr/local/bin/mongodb_exporter -logtostderr -groups.enabled 'asserts,durability,background_flusshing,connections,extra_info,global_lock,index_counters,network,op_counters,op_counters_repl,memory,locks,metrics'
User=prometheus

[Install]
WantedBy=multi-user.target
EOL

cat > /lib/systemd/system/node_exporter.service <<EOL
[Unit]
Description=Node Exporter for mongo

[Service]
Type=simple
Restart=always
ExecStart=/usr/local/bin/node_exporter
User=node_exporter

[Install]
WantedBy=multi-user.target
EOL

systemctl daemon-reload
systemctl start node_exporter
systemctl enable node_exporter