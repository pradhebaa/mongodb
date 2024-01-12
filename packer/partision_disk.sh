#! /bin/sh
sudo mkfs.xfs -L mongodata /dev/sdf
sudo mkfs.xfs -L mongojournal /dev/sdg
sudo mkfs.xfs -L mongolog /dev/sdh
sudo mkdir /data
sudo mkdir /journal
sudo mkdir /log
sudo mount -t xfs /dev/sdf /data
sudo mount -t xfs /dev/sdg /journal
sudo mount -t xfs /dev/sdh /log
sudo ln -s /journal /data/journal
sudo chown mongod:mongod /data
sudo chown mongod:mongod /log/
sudo chown mongod:mongod /journal/

cat >> /etc/fstab << EOL
/dev/sdf /data    xfs defaults,auto,noatime,noexec 0 0
/dev/sdg /journal xfs defaults,auto,noatime,noexec 0 0
/dev/sdh /log     xfs defaults,auto,noatime,noexec 0 0
EOL