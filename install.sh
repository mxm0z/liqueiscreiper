#!/bin/bash
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | sudo apt-key add -

echo "deb https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.2.list

apt update -y

apt install -y python3-pip gnupg mongodb-org
pip3 install python-magic bottle pymongo

systemctl start mongod
systemctl enable mongod
systemctl status mongod

netstat -plntu | grep 27017

mongo --eval "db.runCommand({ connectionStatus: 1 })" > /dev/null 2>&1

db="leakScraper"

mongo --eval "db.credentials.createIndex({\"d\":\"hashed\"})" "$db" > /dev/null 2>&1
mongo --eval "db.credentials.createIndex({\"l\":\"hashed\"})" "$db" > /dev/null 2>&1
mongo --eval "db.createCollection(\"leaks\")" "$db" > /dev/null 2>&1
mongo --eval "db.createUser({user:\"admin\", pwd:\"admin123\", roles:[{role:\"root\", db:"$db"}]})" > /dev/null 2>&1

sed -i 's/ExecStart=\/usr\/bin\/mongod --config \/etc\/mongod\.conf/ExecStart=\/usr\/bin\/mongod --auth --config \/etc\/mongod\.conf/g' /lib/systemd/system/mongod.service

systemctl daemon-reload

service mongod restart

echo "[+] All done. In order to connect, type 'mongo -u <user> -p <password> --authenticationDatabase <database>'"
