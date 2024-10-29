#!/bin/bash
########################################################
#
# 1. 安装常用软件
# 2. 找到备份文件，根据备份文件前面的用户名创建用户，并将数据解压至该目录下,cron要处理
# 3. 安装docker
# 4. 修改sshd，打开防火墙
# 1. install docker,sqlite3,apps and create user
# 2. initial user directory
# 3. enable firewall and open 
#
#
#
########################################################
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


execute_user()
{
username=`cat /etc/passwd|grep rshun|wc -l`
if [ $username -eq 1 ]
then
    usermod -G docker rshun
fi

echo "
cd /home/rshun
mkdir -p backup bin csv data etc html lib shell src obj tmp src/py src/tmp
cd /home/rshun
git clone git@github.com:rshun/shuncs.git
git clone git@github.com:rshun/stock.git
git clone git@github.com:rshun/keyMaster.git
git clone git@github.com:rshun/rules.git

" >>/home/rshun/rshun.sh

chmod 777 /home/rshun/rshun.sh
su - rshun -c "sh /home/rshun/rshun.sh"
su - rshun -c "rm /home/rshun/rshun.sh"

echo "
alias l='ls -ltr'
set -o vi
export EDITOR=vi
export PATH=$PATH:$HOME/bin:$HOME/shell
" >> /home/rshun/.profile
}

enable_firewall()
{
    ufw enable
    ufw allow 39281/tcp
    ufw reload
}

#main
if [ $# -eq 1 ]
then
    port=$1
else
    port=39281
fi

echo "
alias l='ls -ltr'
set -o vi
export EDITOR=vi
export PATH=$PATH:$HOME/shell
" >>$HOME/.profile

mkdir shell tmp
cd tmp
install
download sshd.sh $port
download instdocker.sh
download addusr.sh rshun
execute_user

enable_firewall
timedatectl set-timezone Asia/Shanghai
echo "please execute follow commands after install finish."
echo "add user password"
echo "modify root password"