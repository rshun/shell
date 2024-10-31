#!/bin/bash
#############################################################################
#
# 1. make default docker-compose.yml
# 2. make sure you have docker pull environment.
#
# 
#############################################################################
USER_NAME=calib
GROUP_NAME=apps
ROOT_PATH=/home/$USER_NAME
DOCKER_CONFIG=$ROOT_PATH/docker-compose.yml
CONFIG_PATH=$ROOT_PATH/config
BOOK_LIBRARY=/Books

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
echo "services:
  calibre-web:
    image: linuxserver/calibre-web:latest
    container_name: calibre-web
    environment:
      - PUID=`id -u "$USER_NAME"`
      - PGID=`id -g "$USER_NAME"`
      - TZ=Asia/Shanghai
    volumes:
      - ./config:/config
      - /Books:/library
      - DOCKER_MODS=linuxserver/mods:universal-calibre
    ports:
      - 127.0.0.1:8083:8083
    restart: unless-stopped
" >$DOCKER_CONFIG

mkdir -p $CONFIG_PATH
}

config()
{
wget -P $CONFIG_PATH https://github.com/janeczku/calibre-web/raw/master/library/metadata.db

chown -R $USER_NAME:$GROUP_NAME $ROOT_PATH
usermod -aG docker $USER_NAME
}

#main
if [ ! -d $BOOK_LIBRARY ]
then
    mkdir -p $BOOK_LIBRARY
fi

createUser
install
config
echo "the config file is finish. "
echo "execute passwd" $USER_NAME" modify password"
echo "then execute docker compose up -d"