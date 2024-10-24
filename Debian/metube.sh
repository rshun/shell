#!/bin/bash
#############################################################################
#
# 1. make default docker-compose.yml
# 2. make sure you have docker pull environment.
#
# 
#############################################################################
if [ -f /home/metube/docker-compose.yml ]
then
    cp /home/metube/docker-compose.yml /home/metube/docker-compose.yml.bak
fi

cd /home/metube
echo "services:
  metube:
    image: ghcr.io/alexta69/metube
    container_name: metube
    restart: unless-stopped
    ports:
      - \"8081:8081\"
    volumes:
      - ./downloads:/downloads
    environment:
      - URL_PREFIX=/metube
" >/home/metube/docker-compose.yml
echo "      - UID="`id -u metube` >>/home/metube/docker-compose.yml
echo "      - GID="`id -g metube` >>/home/metube/docker-compose.yml
echo "the config file is finish. "
echo "please execute docker compose up -d"
