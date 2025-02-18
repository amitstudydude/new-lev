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
cat <<EOF > docker-compose.yml
version: '3'
services:
  guacdb:
    container_name: guacamoledb
    image: mariadb:10.9.5
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: 'MariaDBRootPass'
      MYSQL_DATABASE: 'guacamole_db'
      MYSQL_USER: 'guacamole_user'
      MYSQL_PASSWORD: 'MariaDBUserPass'
    volumes:
      - './db-data:/var/lib/mysql'
    network_mode: "host"  # Add network mode for localhost
  guacd:
    container_name: guacd
    image: guacamole/guacd:1.4.0
    restart: unless-stopped
    network_mode: "host"  # Add network mode for localhost
  guacamole:
    container_name: guacamole
    image: guacamole/guacamole:1.4.0
    restart: unless-stopped
    environment:
      GUACD_HOSTNAME: "guacd"
      MYSQL_HOSTNAME: "guacdb"
      MYSQL_DATABASE: "guacamole_db"
      MYSQL_USER: "guacamole_user"
      MYSQL_PASSWORD: "MariaDBUserPass"
      TOTP_ENABLED: "true"
    depends_on:
      - guacdb
      - guacd
    network_mode: "host"  # Add network mode for localhost
volumes:
  db-data:
EOF
# Step 4: Start the services using Docker Compose
docker-compose up -d
# Step 5: Copy the SQL initialization file into the database container
docker cp initdb.sql guacamoledb:/initdb.sql

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


docker-compose down
# Step 8: Note on accessing Guacamole
echo "Access Guacamole at: http://localhost:8080/guacamole"
echo "Default username/password: guacadmin/guacadmin"
echo "Remember to set up TOTP if enabled."


#docker run --name guacd -d guacamole/guacd:1.4.0
#docker run --name guacamole --link guacd:guacd  -p 8080:8080  -e GUACD_HOSTNAME=guacd  -e MYSQL_HOSTNAME=guacamoledb -e MYSQL_DATABASE=guacamole_db  -e MYSQL_USER=guacamole_user  -e MYSQL_PASSWORD=MariaDBUserPass  -d guacamole/guacamole:1.4.0
echo "Guacamole installation completed!"
echo "Access Guacamole at http://<Your-IP>:8080/guacamole"
echo "Default Username: guacadmin"
echo "Default Password: guacadmin"
