#!/bin/bash
#############################################################################
#
# 1. make default docker-compose.yml
# 2. make sure you have docker pull environment.
#
# 
#############################################################################
#system config
USER_NAME=jelly
GROUP_NAME=apps
ROOT_PATH=/home/$USER_NAME
DOCKER_CONFIG=$ROOT_PATH/docker-compose.yml

#app config
CONFIG_PATH=$ROOT_PATH/config
CACHE_PATH=$ROOT_PATH/cache

#self path
MOVIES_PATH=/Movie

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
mkdir -p $CONFIG_PATH $CACHE_PATH
echo "services:
  jellyfin:
    image: jellyfin/jellyfin
    container_name: jellyfin
    user: `id -u "$USER_NAME"`:`id -g "$USER_NAME"`
    network_mode: 'host'
    volumes:
      - "$CONFIG_PATH":/config
      - "$CACHE_PATH":/cache
      - type: bind
        source: "$MOVIES_PATH"
        target: /Movies
        read_only: true
      # Optional - extra fonts to be used during transcoding with subtitle burn-in
#      - type: bind
#        source: /path/to/fonts
#        target: /usr/local/share/fonts/custom
#        read_only: true
    restart: 'unless-stopped'
    # Optional - alternative address used for autodiscovery
    environment:
      - JELLYFIN_PublishedServerUrl=http://example.com
    # Optional - may be necessary for docker healthcheck to pass if running in host network mode
    extra_hosts:
      - 'host.docker.internal:host-gateway'">$DOCKER_CONFIG
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

check()
{
if [ ! -d $MOVIES_PATH ]
then
    echo $MOVIES_PATH" is not exist."
    exit -1
fi
}

#main
check
createUser
install
config
dockge
echo "the config file is finish. "
echo "execute docker compose up -d use "$USER_NAME