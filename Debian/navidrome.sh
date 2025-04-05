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
DOCKER_CONFIG=docker-compose.yml
DOCKGE_PATH=/opt/stacks

#app config
DATA_PATH=$ROOT_PATH/data
CACHE_PATH=$ROOT_PATH/cache

#self path
MUSIC_LIBRARY=/Music


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

docker_yml()
{
echo "services:
  navidrome:
    image: deluan/navidrome:latest
    user: `id -u "$USER_NAME"`:`id -g "$USER_NAME"` # should be owner of volumes
    ports:
      - 15121:4533
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
      - \"$MUSIC_LIBRARY:/music:ro\"" >$ROOT_PATH/$DOCKER_CONFIG
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
}

config_dockge()
{
if [ -d $DOCKGE_PATH ]
then
    mkdir -p $DOCKGE_PATH/$USER_NAME
    mv $ROOT_PATH/$DOCKER_CONFIG $DOCKGE_PATH/$USER_NAME
    chown -R $USER_NAME:$GROUP_NAME  $DOCKGE_PATH/$USER_NAME
fi
}

#main
check
createUser
docker_yml
config_app
config_dockge

echo "config file is success. "
echo "then execute docker compose up -d"