#!/bin/bash
#############################################################################
#
# 1. 
# 2.
#
# 
#############################################################################
FILEBROWSER_VERSION=2.31.2
USER_NAME=filebrowser
GROUP_NAME=app
ROOT_PATH=/home/$USER_NAME

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
    cd /root/tmp
    if [ ! -f addusr.sh ]
    then
        wget https://raw.githubusercontent.com/rshun/shell/master/Debian/addusr.sh && chmod +x addusr.sh
    fi

    ./addusr.sh $USER_NAME $GROUP_NAME
    rm addusr.sh
fi
}

downloadfile()
{
cd /root/tmp
address="https://github.com/filebrowser/filebrowser/releases/download/v"$FILEBROWSER_VERSION"/linux-amd64-filebrowser.tar.gz"
wget $address

if [ ! -f linux-amd64-filebrowser.tar.gz ]
then
    echo "file download error."
    exit 1
fi

tar zxvf linux-amd64-filebrowser.tar.gz filebrowser
}

config()
{
cd $ROOT_PATH

mkdir bin downloads etc log
echo "{
  \"port\": 38612,
  \"baseURL\": \"/dofiles\",
  \"address\": \"127.0.0.1\",
  \"log\": \""$ROOT_PATH"/log/filebrowser.log\",
  \"database\": \""$ROOT_PATH"/etc/filebrowser.db\",
  \"root\": \""$ROOT_PATH"/downloads\"
}" >$ROOT_PATH/etc/filebrowser.json

echo "[Unit]
Description=File Browser
After=network.target

[Service]
User="$USER_NAME
"Group="$GROUP_NAME
"ExecStart="$ROOT_PATH"/bin/filebrowser -c "$ROOT_PATH"/etc/filebrowser.json

[Install]
WantedBy=multi-user.target">/etc/systemd/system/filebrowser.service

mv /root/tmp/filebrowser $ROOT_PATH/bin

chmod 750 $ROOT_PATH
chmod 777 $ROOT_PATH/downloads
chmod +x $ROOT_PATH/bin/filebrowser
chown -R $USER_NAME:$GROUP_NAME $ROOT_PATH

}

createUser
downloadfile
config
systemctl daemon-reload
systemctl enable filebrowser.service
systemctl start filebrowser.service
echo "now filebrowser is install finish."
echo "execute passwd" $USER_NAME" modify password"