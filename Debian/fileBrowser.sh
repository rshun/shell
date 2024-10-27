#!/bin/bash
#############################################################################
#
# 1. create user filebrowser
# 2. download filebrowser
# 3. add filebrowser to system service
# 
#############################################################################
FILEBROWSER_VERSION=2.31.2
USER_NAME=filebrowser
GROUP_NAME=app
ROOT_PATH=/home/$USER_NAME
TEMP_PATH=$ROOT_PATH/tmp
DOWNLOAD_PATH=/home/shared/downloads

#create filebrowser and app group
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
        fi
    fi

    ./addusr.sh $USER_NAME $GROUP_NAME
    usermod -L $USER_NAME
    rm addusr.sh
fi
}

downloadfile()
{
cd $TEMP_PATH
address="https://github.com/filebrowser/filebrowser/releases/download/v"$FILEBROWSER_VERSION"/linux-amd64-filebrowser.tar.gz"
wget $address

if [ ! -f linux-amd64-filebrowser.tar.gz ]
then
    echo "file download error."
    exit 1
fi

tar zxvf linux-amd64-filebrowser.tar.gz -C $ROOT_PATH/bin filebrowser
if [ ! -f $ROOT_PATH/bin/filebrowser ]
then
    echo $ROOT_PATH"/bin/filebrowser is not exist."
    exit 1
fi
chmod +x $ROOT_PATH/bin/filebrowser
}

config()
{
cd $ROOT_PATH

mkdir -p $DOWNLOAD_PATH
chmod 777 $DOWNLOAD_PATH

mkdir bin etc log tmp
echo "{
  \"port\": 38612,
  \"baseURL\": \"/dofiles\",
  \"address\": \"127.0.0.1\",
  \"log\": \""$ROOT_PATH"/log/filebrowser.log\",
  \"database\": \""$ROOT_PATH"/etc/filebrowser.db\",
  \"root\": \""$DOWNLOAD_PATH"\"
}" >$ROOT_PATH/etc/filebrowser.json

echo "[Unit]
Description=File Browser
After=network.target

[Service]
User="$USER_NAME"
Group="$GROUP_NAME"
ExecStart="$ROOT_PATH"/bin/filebrowser -c "$ROOT_PATH"/etc/filebrowser.json

[Install]
WantedBy=multi-user.target">/etc/systemd/system/filebrowser.service

}

if [ $# -eq 1 ]
then
    FILEBROWSER_VERSION=$1
fi

createUser
config
downloadfile

chown -R $USER_NAME:$GROUP_NAME $ROOT_PATH

systemctl daemon-reload
systemctl enable filebrowser.service
systemctl start filebrowser.service
echo "now filebrowser is install finish."
echo "execute passwd" $USER_NAME" modify password"