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

mkdir -p $DATA_PATH
mkdir -p $CACHE_PATH
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

#main
if [ ! -d $MUSIC_LIBRARY ]
then
    echo $MUSIC_LIBRARY" is not exist"
    exit -1
fi

createUser
install
config
dockge
echo "the config file is finish. "
echo "execute passwd" $USER_NAME" modify password"
echo "then execute docker compose up -d"