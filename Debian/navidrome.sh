#!/bin/bash
#############################################################################
#
# 1. make default docker-compose.yml
# 2. make sure you have docker pull environment.
#
# 
#############################################################################
#system config
USER_NAME=navid
GROUP_NAME=apps
ROOT_PATH=/home/$USER_NAME
DOCKER_CONFIG=$ROOT_PATH/docker-compose.yml

#app config
DATA_PATH=$ROOT_PATH/data
CACHE_PATH=$ROOT_PATH/cache

#self path
MUSIC_LIBRARY=/Music

#shell
CREATE_USER=addusr.sh
INSTALL_DOCKGE=instdockge.sh

docker_yml()
{
echo "services:
  navidrome:
    image: deluan/navidrome:latest
    user: `id -u "$USER_NAME"`:`id -g "$USER_NAME"` # should be owner of volumes
    ports:
      - \"127.0.0.1:15121:4533\"
    restart: unless-stopped
    environment:
      ND_BASEURL: \"/music\"
      ND_DEFAULTLANGUAGE: \"zh-Hans\"
      ND_DEFAULTTHEME: \"Auto\"
      ND_LOGLEVEL: info
      ND_SCANSCHEDULE: 1h
      ND_SESSIONTIMEOUT: 24h
    volumes:
      - \"$DATA_PATH:/data\"
      - \"$CACHE_PATH:/cache\"
      - \"$MUSIC_LIBRARY:/music:ro\"" >$DOCKER_CONFIG
}

config_app()
{
mkdir -p $DATA_PATH
mkdir -p $CACHE_PATH

chown -R $USER_NAME:$GROUP_NAME $ROOT_PATH
usermod -aG docker $USER_NAME
usermod -L $USER_NAME
}

check()
{
if [ ! -d $MUSIC_LIBRARY ]
then
    echo $MUSIC_LIBRARY" is not exist"
    exit -1
fi

if [ ! -f $CREATE_USER ]
then
    echo $CREATE_USER" is not exist"
    exit -1
fi

if [ ! -f $INSTALL_DOCKGE ]
then
    echo $INSTALL_DOCKGE" is not exist"
    exit -1
fi
}

#main
check
source $CREATE_USER $USER_NAME $GROUP_NAME
docker_yml
config_app
source $INSTALL_DOCKGE $USER_NAME $GROUP_NAME $DOCKER_CONFIG

echo "config file is success. "
echo "then execute docker compose up -d"