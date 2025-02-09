#!/bin/bash
cd /tmp
curl -O https://kasm-static-content.s3.amazonaws.com/kasm_release_1.16.1.98d6fa.tar.gz
tar -xf kasm_release_1.16.1.98d6fa.tar.gz
lsof -i :3389
pid=$(lsof -t -i:3389)
sudo kill -9 $pid
pid=$(lsof -t -i:7887)
sudo kill -9 $pid
sudo bash kasm_release/install.sh --accept-eula --swap-size 4096 --admin-password root -L 7887
cd /opt/kasm/current/certs
rm kasm_nginx.crt kasm_nginx.key
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /opt/kasm/current/certs/kasm_nginx.key -out /opt/kasm/current/certs/kasm_nginx.crt -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"
sudo chown kasm:kasm /opt/kasm/current/certs/kasm_nginx.key /opt/kasm/current/certs/kasm_nginx.crt
sudo chmod 600 /opt/kasm/current/certs/kasm_nginx.key
sudo /opt/kasm/bin/stop
sudo /opt/kasm/bin/start
