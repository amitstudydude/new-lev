#!/bin/bash
echo "Cleaning up existing Docker containers, images, and volumes..."
apt install docker-compose
docker rm -f guacamoledb guacd guacamole 2>/dev/null || true
docker rmi -f guacamole/guacamole:1.4.0 guacamole/guacd:1.4.0 mariadb:10.9.5 2>/dev/null || true
docker volume rm $(docker volume ls -q --filter dangling=true) 2>/dev/null || true
rm -f initdb.sql
rm -rf ./db-data
echo "Pulling Docker images..."
docker pull guacamole/guacamole:1.4.0
docker pull guacamole/guacd:1.4.0
docker pull mariadb:10.9.5
echo "Generating initial database SQL file..."
docker run --rm guacamole/guacamole:1.4.0 /opt/guacamole/bin/initdb.sh --mysql > initdb.sql
echo "Starting MariaDB container..."


echo "version: '3'" > docker-compose.yml
echo "" >> docker-compose.yml
echo "services:" >> docker-compose.yml
echo "  guacdb:" >> docker-compose.yml
echo "    container_name: guacamoledb" >> docker-compose.yml
echo "    image: mariadb:10.9.5" >> docker-compose.yml
echo "    restart: unless-stopped" >> docker-compose.yml
echo "    environment:" >> docker-compose.yml
echo "      MYSQL_ROOT_PASSWORD: 'MariaDBRootPass'" >> docker-compose.yml
echo "      MYSQL_DATABASE: 'guacamole_db'" >> docker-compose.yml
echo "      MYSQL_USER: 'guacamole_user'" >> docker-compose.yml
echo "      MYSQL_PASSWORD: 'MariaDBUserPass'" >> docker-compose.yml
echo "    volumes:" >> docker-compose.yml
echo "      - './db-data:/var/lib/mysql'" >> docker-compose.yml
echo "volumes:" >> docker-compose.yml
echo "  db-data:" >> docker-compose.yml


docker-compose up -d

docker cp initdb.sql guacamoledb:/initdb.sql
sleep 5
sudo /usr/bin/expect <<EOF
spawn docker exec -it guacamoledb bash
sleep 1
send -- "cat /initdb.sql | mysql -u root -p guacamole_db\r"
sleep 1
send -- "MariaDBRootPass\r"
sleep 1
send -- "exit\r"
expect eof
EOF
cp docker-compose.yml docker-compose.yml.bak



cat << EOF > docker-compose.yml
version: '3'
services:
  guacdb:
    container_name: guacamoledb
    image: mariadb:10.9.5
    restart: unless-stopped
    network: host
    environment:
      MYSQL_ROOT_PASSWORD: 'MariaDBRootPass'
      MYSQL_DATABASE: 'guacamole_db'
      MYSQL_USER: 'guacamole_user'
      MYSQL_PASSWORD: 'MariaDBUserPass'
    volumes:
      - './db-data:/var/lib/mysql'
  guacd:
    container_name: guacd
    image: guacamole/guacd:1.4.0
    restart: unless-stopped
    network: host
  guacamole:
    container_name: guacamole
    image: guacamole/guacamole:1.4.0
    restart: unless-stopped
    network: host
    ports:
      - 8080:8080
    environment:
      GUACD_HOSTNAME: "guacd"
      MYSQL_HOSTNAME: "guacdb"
      MYSQL_DATABASE: "guacamole_db"
      MYSQL_USER: "guacamole_user"
      MYSQL_PASSWORD: "MariaDBUserPass"
    depends_on:
      - guacdb
      - guacd
volumes:
  db-data:
EOF
docker-compose up -d
rm *yml *yml*
#docker run --name guacd -d guacamole/guacd:1.4.0
#docker run --name guacamole --link guacd:guacd  -p 8080:8080  -e GUACD_HOSTNAME=guacd  -e MYSQL_HOSTNAME=guacamoledb -e MYSQL_DATABASE=guacamole_db  -e MYSQL_USER=guacamole_user  -e MYSQL_PASSWORD=MariaDBUserPass  -d guacamole/guacamole:1.4.0
echo "Guacamole installation completed!"
echo "Access Guacamole at http://<Your-IP>:8080/guacamole"
echo "Default Username: guacadmin"
echo "Default Password: guacadmin"
