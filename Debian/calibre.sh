#!/bin/bash
#############################################################################
#
# 1. make default docker-compose.yml
# 2. make sure you have docker pull environment.
# 3. use domain name if caddy install 
# 
#############################################################################
#system config
USER_NAME=calib
GROUP_NAME=apps
ROOT_PATH=/home/$USER_NAME
DOCKER_CONFIG=$ROOT_PATH/docker-compose.yml

#app config
CONFIG_PATH=$ROOT_PATH/config
TEMP_PATH=$ROOT_PATH/tmp
CADDY_FILE=/etc/caddy/Caddyfile
PORT=15122

#self path
BOOKS_PATH=$ROOT_PATH/books

#dockge path
DOCKGE_STACK=/opt/stacks

createUser()
{
appgroup=`cat /etc/group|grep $GROUP_NAME|wc -l`
if [ $appgroup -eq 0 ]
then
    groupadd $GROUP_NAME
fi

num=`cat /etc/passwd|grep "$USER_NAME"|wc -l`
if [ $num -eq 0 ]
then
    if [ ! -f addusr.sh ]
    then
        wget https://raw.githubusercontent.com/rshun/shell/master/Debian/addusr.sh && chmod +x addusr.sh
    fi

    if [ ! -f addusr.sh ]
    then
        echo "addusr.sh is not exist"
        exit -1
    fi

    ./addusr.sh $USER_NAME $GROUP_NAME
    usermod -L $USER_NAME
    rm addusr.sh
fi
}

install()
{
mkdir -p $CONFIG_PATH $TEMP_PATH $BOOKS_PATH
echo "services:
  calibre-web-automated:
    image: crocodilestick/calibre-web-automated:latest
    container_name: calibre-web-automated
    environment:
      - PUID=`id -u "$USER_NAME"`
      - PGID=`id -g "$USER_NAME"`
      - TZ=Asia/Shanghai
      - URL_PREFIX=/calibre
      - DOCKER_MODS=lscr.io/linuxserver/mods:universal-calibre-v7.16.0
    volumes:
      - "$CONFIG_PATH":/config
      - "$TEMP_PATH":/cwa-book-ingest
      - "$BOOKS_PATH":/calibre-library
      #- /path/to/your/gmail/credentials.json:/app/calibre-web/gmail.json #Optional
    ports:
      - "$PORT":8083 # Change the first number to change the port you want to access the Web UI, not the second
    restart: unless-stopped">$DOCKER_CONFIG
}

config()
{
chown -R $USER_NAME:$GROUP_NAME $ROOT_PATH
usermod -aG docker $USER_NAME
}

dockge()
{
mkdir -p $DOCKGE_STACK/$USER_NAME
mv $DOCKER_CONFIG $DOCKGE_STACK/$USER_NAME
chown -R $USER_NAME:$GROUP_NAME $DOCKGE_STACK/$USER_NAME
chmod -R 775 $DOCKGE_STACK/$USER_NAME
}

config_caddy()
{
if [ -f $CADDY_FILE ]
then
    echo "http://books.local {
        reverse_proxy 127.0.0.1:"$PORT"
}" >>$CADDY_FILE
systemctl reload caddy
fi
}

#main
createUser
install
config
dockge
config_caddy
echo "the config file is finish. "
echo "cd "$DOCKGE_STACK"/"$USER_NAME
echo "then execute docker compose up -d"