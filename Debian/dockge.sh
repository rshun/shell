#!/bin/bash
#############################################################################
#
# 1. make default docker-compose.yml
# 2. make sure you have docker pull environment.
# 3. use domain name if caddy install 
# 
#############################################################################
#system config
USER_NAME=dockge
GROUP_NAME=apps
ROOT_PATH=/home/$USER_NAME

#app config
DATA_PATH=$ROOT_PATH/data
STACKS_PATH=/opt/stacks
DOCKGE_PATH=/opt/dockge
DOCKER_CONFIG=$DOCKGE_PATH/docker-compose.yml
CADDY_FILE=/etc/caddy/Caddyfile
PORT=127.0.0.1:15001

#other config
GROUP_ID=`cat /etc/group|grep docker|awk -F':' '{print $3}'`

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
mkdir -p $DATA_PATH $STACKS_PATH $DOCKGE_PATH

echo "services:
  dockge:
    image: louislam/dockge:1
    user: `id -u "$USER_NAME"`:"$GROUP_ID"
    restart: unless-stopped
    ports:
      - "$PORT":5001
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - "$DATA_PATH":/app/data
      # Stacks Directory
      # ⚠️ READ IT CAREFULLY. If you did it wrong, your data could end up writing into a WRONG PATH.
      # ⚠️ 1. FULL path only. No relative path (MUST)
      # ⚠️ 2. Left Stacks Path === Right Stacks Path (MUST)
      - "$STACKS_PATH":"$STACKS_PATH"
    environment:
      - URL_PREFIX=/dockge
      # Tell Dockge where to find the stacks
      - DOCKGE_STACKS_DIR="$STACKS_PATH"" >$DOCKER_CONFIG
}

config()
{
usermod -aG docker $USER_NAME
chown -R $USER_NAME:$GROUP_NAME $ROOT_PATH
chown -R $USER_NAME:$GROUP_NAME $STACKS_PATH
chown -R $USER_NAME:$GROUP_NAME $DOCKGE_PATH
chmod 775 $STACKS_PATH $DOCKGE_PATH
}

config_caddy()
{
if [ -f /etc/caddy/Caddyfile ]
then
    echo "http://dockge.local {
        reverse_proxy "$PORT"
    }" >>$CADDY_FILE
fi

}
#main
if [ -z $GROUP_ID ]
then
    echo "docker group is not exist."
    exit -1
fi

createUser
install
config
config_caddy
echo "the config file is finish. "
echo "execute passwd" $USER_NAME" modify password"
echo "then execute docker compose up -d"