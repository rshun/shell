######################################################################################################################
#
# 1. install docker,sqlite3,apps and create user
# 2. initial user directory
# 3. enable firewall and open 
#
#
#
######################################################################################################################

install()
{
    apt update
    apt install build-essential man lsof curl wget ufw sqlite3 libsqlite3-dev python3-pip nginx -y
}

download()
{
    wget -O $shellname https://raw.githubusercontent.com/rshun/shell/master/Debian/$shellname && chmod +x $shellname && ./$shellname $param1
}


execute_user()
{
echo "
cd /home/rshun
mkdir -p backup bin csv data etc html lib shell src obj tmp src/stock src/keyMaster src/py src/tmp
cd /home/rshun/src/stock
git clone https://github.com/rshun/stock.git

cd /home/rshun/src/keyMaster
git clone https://github.com/rshun/keyMaster.git
" >>/home/rshun/rshun.sh

chmod 777 /home/rshun/rshun.sh
su - rshun -c "sh /home/rshun/rshun.sh"
su - rshun -c "rm /home/rshun/rshun.sh"
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
    port = $1
else
    port = 39281
fi

install
download sshd.sh $port
download instdocker.sh
download addusr.sh rshun
usermod -G docker rshun

timedatectl set-timezone Asia/Shanghai
execute_user
enable_firewall