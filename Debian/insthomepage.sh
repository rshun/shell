#!/bin/bash
#############################################################################
#
# 1. make default docker-compose.yml
# 2. make sure you have docker pull environment.
# 3. use domain name if caddy install 
# 
#############################################################################
#system config
USER_NAME=pages
GROUP_NAME=apps
ROOT_PATH=/home/$USER_NAME
DOCKER_CONFIG=docker-compose.yml
DOCKGE_PATH=/opt/stacks

#app config
CONFIG_PATH=$ROOT_PATH/config
PORT=15120

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
echo"services:
  homepage:
    image: ghcr.io/gethomepage/homepage:latest
    container_name: homepage
    ports:
      - "$PORT":3000
    volumes:
      - "$CONFIG_PATH":/app/config # Make sure your local config directory exists
      - /var/run/docker.sock:/var/run/docker.sock # (optional) For docker integrations, see alternative methods
    environment:
      HOMEPAGE_ALLOWED_HOSTS: 127.0.0.1:"$PORT" # required, may need port. See gethomepage.dev/installation/#homepage_allowed_hosts
      PUID: `id -u "$USER_NAME"`
      PGID: `id -g "$USER_NAME"`
">$ROOT_PATH/$DOCKER_CONFIG
}

config_app()
{
mkdir -p $CONFIG_PATH

chown -R $USER_NAME:$GROUP_NAME $ROOT_PATH
usermod -aG docker $USER_NAME
usermod -L $USER_NAME

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

config_caddy()
{
if [ -f /etc/caddy/Caddyfile ]
then
    echo "http://navid.local {
        reverse_proxy 127.0.0.1:"$PORT"
}
" >>$CADDY_FILE
systemctl reload caddy
fi

#main
createUser
docker_yml
config_app
config_dockge
config_caddy

echo "config file is success. "
echo "then execute docker compose up -d"