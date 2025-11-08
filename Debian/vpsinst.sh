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
BAK_HTML=root_html
PORT=39281

#user
USER_NAME=rshun
USER_HOME_DIR=/home/rshun
USER_SHELL=$USER_NAME".sh"

install()
{
    apt update
    apt install build-essential man lsof curl wget ufw sqlite3 libsqlite3-dev python3-pip nginx -y
    if [ $? -ne 0 ]
    then
        exit -1
    fi
}

download()
{
    wget -O $1 https://raw.githubusercontent.com/rshun/shell/master/Debian/$1 && chmod +x $1 && ./$1 $2
}


post_user()
{

echo "
cd "$USER_HOME_DIR"
mkdir -p backup bin csv data etc lib shell src obj tmp src/py
cd "$USER_HOME_DIR/src"
git clone git@github.com:rshun/shuncs.git
git clone git@github.com:rshun/stock.git
git clone git@github.com:rshun/keyMaster.git
git clone git@github.com:rshun/rules.git
git clone git@github.com:rshun/shell.git
git clone git@github.com:rshun/quant.git

" >>$USER_HOME_DIR/$USER_SHELL

chmod 777 $USER_HOME_DIR/$USER_SHELL
su - $USER_NAME -c "sh "$USER_HOME_DIR"/"$USER_SHELL""
su - $USER_NAME -c "rm "$USER_HOME_DIR"/"$USER_SHELL""
}

config_root()
{

cd $HOME
echo "
alias l='ls -ltr'
set -o vi
export EDITOR=vi
export PATH=$PATH:$HOME/shell
" >>$HOME/.profile

mkdir tmp

BAK_CRON_FILE=$BAK_CRON"."$DAY
if [ ! -f $BAK_CRON_FILE ]
then
    echo $BAK_CRON_FILE" is not exist."
else
    crontab -u root $BAK_CRON_FILE
fi


for tarfile in `ls root*.tar.gz`
do
    tar zxvf $tarfile
done

}

enable_firewall()
{
    ufw enable
    ufw allow $PORT/tcp
    ufw reload
}

#main
if [ $# -eq 1 ]
then
    DAY=$1
else
    echo "usage: $0 YYYYMMMDD(backup file)"
    exit -1
fi

config_root $DAY
cd $HOME/tmp
install
download sshd.sh $PORT
download addusr.sh $USER_NAME
post_user

enable_firewall
timedatectl set-timezone Asia/Shanghai
echo "please execute follow commands after install finish."
echo "add user password"
echo "modify root password"