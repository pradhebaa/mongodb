#!/usr/bin/bash

exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

cat > /etc/mongod.conf <<EOL
# mongod.conf
# for documentation of all options, see:
#   http://docs.mongodb.org/manual/reference/configuration-options/
# where to write logging data.
systemLog:
  destination: file
  logAppend: true
  logRotate: reopen
  path: /log/mongod.log
# Where and how to store data.
storage:
  dbPath: /data/db
  journal:
    enabled: true
#  engine:
#  mmapv1:
#  wiredTiger:
# how the process runs
processManagement:
  fork: true  # fork and run in background 
  pidFilePath: /var/run/mongodb/mongod.pid  # location of pidfile
  timeZoneInfo: /usr/share/zoneinfo
# network interfaces
net:
  port: 27017
  bindIpAll: true
security:
  authorization: enabled       
  keyFile: /opt/mongod/keyfile 
#operationProfiling:
replication:
  replSetName: rs0
#sharding:
## Enterprise-Only Options
#auditLog:
#snmp:
EOL

IP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
aws route53 change-resource-record-sets --hosted-zone-id ${dnsZoneId} --change-batch '{ "Comment": "Creating a record set", "Changes": [ { "Action": "UPSERT", "ResourceRecordSet": { "Name": "'"${mongodb_self_name}"'", "Type": "A", "TTL": 120, "ResourceRecords": [ { "Value": "'"$IP"'" } ] } } ] }'

####################################
## MongoDB Init - Join ReplicaSet ##
####################################

function log() {
  local msg="$1"
  local timestamp
  timestamp=$(date --iso-8601=ns)
  echo "[$timestamp] $msg" >>/log/mongodb-init.log
}

mongodb_self_name=${mongodb_self_name}
admin_creds="-u ${mongodb_user} -p ${mongodb_password}"
IFS=, read -ra mongo_all_peers <<< "${mongodb_all_peers_csv}"

for peer in "$${mongo_all_peers[@]}"; do
  if mongo admin --host "$peer" $admin_creds --eval "rs.isMaster()" | grep '"ismaster" : true'; then
    log "Found master: $peer"
    log "Restarting mongod service to apply auth settings..."
    systemctl restart mongod
    log "Adding myself ($mongodb_self_name) to replica set..."
    mongo admin --host "$peer" $admin_creds --eval "rs.add('$mongodb_self_name')"

    sleep 3

    log 'Waiting for replica to reach SECONDARY state...'
    until printf '.' && [[ $(mongo admin $admin_creds --quiet --eval "rs.status().myState") == '2' ]]; do
      sleep 3
    done

    log '✓ Replica reached SECONDARY state.'
    log 'Starting mongodb_exporter service'
    export MONGODB_URI=mongodb://${mongodbExporterUser}:${mongodbExporterUserPass}@localhost:27017
    sed -i -e '/ExecStart/s/$/ -mongodb.uri $MONGODB_URI/' /lib/systemd/system/mongodb_exporter.service
    systemctl daemon-reload 
    systemctl start mongodb_exporter.service 
    systemctl start node_exporter.service  
  fi
done
