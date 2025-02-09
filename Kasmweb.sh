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

