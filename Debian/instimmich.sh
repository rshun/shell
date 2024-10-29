#!/bin/bash
#############################################################################
#
# 1. autodown download env and docker-compose.yml
# 2. modify UPLOAD_LOCATION and DB_DATA_LOCATION in .env
# 3. modify port in docker-compose.yml
# 4. create directory
# 
# immich version: 1.117
#############################################################################
YAML_FILENAME=docker-compose.yml
ENV_FILENAME=.env
NEW_UPLOAD=upload
NEW_DATABASE_LOCATION=data
USER_NAME=immich
GROUP_NAME=apps
ROOT_PATH=/home/$USER_NAME

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
        exit 1
    fi

    ./addusr.sh $USER_NAME $GROUP_NAME
    rm addusr.sh
fi
}

modify_env()
{
cd $ROOT_PATH

password=`openssl rand -hex 16`
sed -i "s/DB_PASSWORD=postgres/DB_PASSWORD=${password}/g" $ENV_FILENAME
sed -i "s/\# TZ=Etc\/UTC/TZ=Asia\/Shanghai/g" $ENV_FILENAME
sed -i "s/UPLOAD_LOCATION=\.\/library/UPLOAD_LOCATION=\.\/upload/g" $ENV_FILENAME
sed -i "s/DB_DATA_LOCATION=\.\/postgres/DB_DATA_LOCATION=\.\/data/g" $ENV_FILENAME

echo "PUID="`id -u "$USER_NAME"` >>$ENV_FILENAME
echo "PGID="`id -g "$USER_NAME"` >>$ENV_FILENAME
}

modify_yml()
{
    sed -i 's/2283:/127.0.0.1:2283:/g' $YAML_FILENAME
    sed -i '/container_name/a \    user: \${PUID}:\${PGID}' $YAML_FILENAME
}

create_dir()
{
cd $ROOT_PATH

if [ ! -d $NEW_DATABASE_LOCATION ]
then
    mkdir $NEW_DATABASE_LOCATION
fi

if [ ! -d $NEW_UPLOAD ]
then
    mkdir $NEW_UPLOAD
fi
}

download_conf()
{
cd $ROOT_PATH
wget -O docker-compose.yml https://github.com/immich-app/immich/releases/latest/download/docker-compose.yml
wget -O .env https://github.com/immich-app/immich/releases/latest/download/example.env

if [ ! -f .env ]
then
    echo "not exist .env file"
    exit -1
fi

if [ ! -f docker-compose.yml ]
then
    echo "not exist docker-compose.yml"
    exit -1
fi

cp .env example.env
cp docker-compose.yml docker-compose.yml.bak
}

change_privilege()
{
usermod -L $USER_NAME
usermod  -aG docker $USER_NAME
chown -R $USER_NAME:$GROUP_NAME $ROOT_PATH
}

#main
createUser
download_conf
create_dir
modify_env
modify_yml
change_privilege

echo "immich install is finish. now execute step:"
echo " 1. modify immich passowd. passwd immich"
echo " 2. check "$ROOT_PATH"/docker-compose.yml"
echo " 3. start it. docker compose up -d"
