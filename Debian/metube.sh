#!/bin/bash
#############################################################################
#
# 1. make default docker-compose.yml
# 2. make sure you have docker pull environment.
#
# 
#############################################################################
USER_NAME=metube
GROUP_NAME=app
ROOT_PATH=/home/$USER_NAME
DOWNLOAD_PATH=/home/filebrowser/downloads
DOCKER_CONFIG=$DOWNLOAD_PATH/docker-compose.yml

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
    cd /root/tmp
    if [ ! -f addusr.sh ]
    then
        wget https://raw.githubusercontent.com/rshun/shell/master/Debian/addusr.sh && chmod +x addusr.sh
    fi

    ./addusr.sh $USER_NAME $GROUP_NAME
    usermod -L $USER_NAME
    rm addusr.sh
fi
}

install()
{
if [ -f $DOCKER_CONFIG ]
then
    cp $DOCKER_CONFIG $DOCKER_CONFIG.bak
fi

echo "services:
  metube:
    image: ghcr.io/alexta69/metube
    container_name: metube
    restart: unless-stopped
    ports:
      - \"8081:8081\"
    volumes:
      - "$DOWNLOAD_PATH":/downloads
    environment:
      - URL_PREFIX=/metube" >$DOCKER_CONFIG
echo "      - UID="`id -u "$USER_NAME"` >>$DOCKER_CONFIG
echo "      - GID="`id -g "$USER_NAME"` >>$DOCKER_CONFIG
}

config()
{
chown -R $USER_NAME:$GROUP_NAME $ROOT_PATH
usermod -aG docker $USER_NAME
}

checkDocker()
{
result=`docker version`
if [ $? -ne 0 ]
then
    echo "please install docker first"
    exit 1
fi

if [ ! -d $DOWNLOAD_PATH ]
then
    echo $DOWNLOAD_PATH" is not exist"
    exit 1
fi
}

if [ ! -d /root/tmp ]
then
    mkdir /root/tmp
fi
checkDocker
createUser
install
config

echo "the config file is finish. "
echo "execute passwd" $USER_NAME" modify password"
echo "then execute docker compose up -d"
