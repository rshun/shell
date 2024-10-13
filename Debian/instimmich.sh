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

modify_env()
{

password=`openssl rand -hex 16`
sed -i "s/DB_PASSWORD=postgres/DB_PASSWORD=${password}/g" $ENV_FILENAME
sed -i "s/UPLOAD_LOCATION=\.\/library/UPLOAD_LOCATION=\.\/upload/g" $ENV_FILENAME
sed -i "s/DB_DATA_LOCATION=\.\/postgres/DB_DATA_LOCATION=\.\/data/g" $ENV_FILENAME

echo "PUID="`id -u immich` >>.env
echo "PGID="`id -g immich` >>.env
}

modify_yml()
{
    sed -i 's/2283:/41669:/g' $YAML_FILENAME
    sed -i '/container_name/a \    user: \${PUID}:\${PGID}' $YAML_FILENAME
}

create_dir()
{

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

download_conf
create_dir
modify_env
modify_yml
