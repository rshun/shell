#!/bin/bash
########################################################
#
# 1. 安装常用软件
# 2. 找到备份文件，根据备份文件前面的用户名创建用户，解压数据
# 3. 修改sshd，打开防火墙
# 1. install apps and create user
# 2. initial user directory
# 3. enable firewall and open 
#
#
########################################################
#root
BAK_CRON=root_cron
TMP_PATH=$HOME/tmp

install()
{
echo "now install apps......"
    apt update
    apt install build-essential man lsof curl wget ufw sqlite3 libsqlite3-dev python3-pip python3-venv nginx git -y
    if [ $? -ne 0 ]
    then
        echo "apps install error..."
        exit 1
    fi

echo "apps install finished..."
}

download()
{
    wget -O $1 https://raw.githubusercontent.com/rshun/shell/master/Debian/$1 && chmod +x $1
}


post_user()
{

echo "
cd "$USER_HOME_DIR"
mkdir -p backup bin csv data etc lib shell src obj tmp src/py

for tarfile in `ls $USER_NAME*.tar.gz`
do
    tar zxvf $tarfile
    rm -rf $tarfile
done

cd "$USER_HOME_DIR/src"
wget -O instPyStock.sh https://raw.githubusercontent.com/rshun/shell/master/Debian/instPyStock.sh && chmod +x instPyStock.sh

" >>$USER_HOME_DIR/$USER_SHELL

chmod 777 $USER_HOME_DIR/$USER_SHELL
su - $USER_NAME -c "sh "$USER_HOME_DIR"/"$USER_SHELL""
su - $USER_NAME -c "rm "$USER_HOME_DIR"/"$USER_SHELL""
}

config_root()
{
echo "configure root...."
echo "
alias l='ls -ltr'
set -o vi
export EDITOR=vi
export PATH=$PATH:$HOME/shell
" >>$HOME/.profile

source $HOME/.profile

BAK_CRON_FILE=$TMP_PATH/$BAK_CRON"."$DAY
if [ ! -f $BAK_CRON_FILE ]
then
    echo $BAK_CRON_FILE" is not exist."
else
    crontab -u root $BAK_CRON_FILE
    rm $BAK_CRON_FILE
fi

for tarfile in `ls $TMP_PATH/root*.tar.gz`
do
    tar zxvf $tarfile
    rm -rf $tarfile
done

cd /etc/nginx/sites-available
for confile in `ls *`
do
    if [ ! -f /etc/nginx/sites-enabled/$confile ]
    then
        ln -s /etc/nginx/sites-available/$confile /etc/nginx/sites-enabled/
    fi
done

systemctl enable nginx
systemctl start nginx

echo "configure root is end.."
}

config_user()
{
download addusr.sh 
cd $TMP_PATH
for tarfile in `ls *.tar.gz`
do
    username=`echo $tarfile|cut -d'_' -f1`
    result=`cat /etc/passwd|grep $username|wc -l`
    if [ $result -eq 0 ]
    then
        echo $username" is not exist"
        read -p "是否创建用户(输入'Y'继续): " choice
        if [ "$choice" == "Y" ]; then
            ./addusr.sh $username
        fi
    fi
    tar -zxvf $tarfile -C /home/$username
    rm -rf $tarfile
done

for cronfile in `ls *cron.$DAY`
do
    username=`echo $cronfile|cut -d'_' -f1`
    result=`cat /etc/passwd|grep $username|wc -l`
    if [ $result -eq 1 ]
    then
        crontab -u $username $cronfile
        rm -rf $cronfile
    fi
done
}

enable_firewall()
{
echo "enable firewall...."
    ufw enable
    ufw allow $PORT/tcp
    ufw allow 'Nginx Full'
    ufw reload
}

configure_ssh()
{
echo "download sshd script and configure"
cd $TMP_PATH
download sshd.sh
./sshd.sh $PORT
rm sshd.sh
echo "configure sshd is finished...."
}

#main
if [ $# -lt 2 ]
then
    echo "usage: $0 YYYYMMMDD(backup file) PORT"
    exit 1
fi

DAY=$1
PORT=$2

if [ ! -d $TMP_PATH ]
then 
    mkdir -p $TMP_PATH
fi
timedatectl set-timezone Asia/Shanghai
install

configure_ssh
enable_firewall
config_root $DAY

config_user
rm -rf $TMP_PATH/addusr.sh
echo "please execute follow commands after install finish."
echo "add user password"
echo "modify root password"
