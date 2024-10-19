apt update
apt install build-essential man lsof curl wget ufw sqlite3 libsqlite3-dev python3-pip nginx -y

timedatectl set-timezone Asia/Shanghai

# adduser and install docker
wget -O sshd.sh https://raw.githubusercontent.com/rshun/shell/master/Debian/sshd.sh
wget -O addusr.sh https://raw.githubusercontent.com/rshun/shell/master/Debian/addusr.sh 
wget -O instdocker.sh https://raw.githubusercontent.com/rshun/shell/master/Debian/instdocker.sh
chmod +x addusr.sh instdocker.sh sshd.sh
./sshd.sh
./instdocker.sh
./addusr rshun docker

# execute shell
echo "
cd /home/rshun
mkdir -p backup bin csv data etc html lib shell src obj tmp src/stock src/keyMaster src/py src/tmp
cd /home/rshun/src/stock
git clone https://github.com/rshun/stock.git

cd /home/rshun/src/keyMaster
git clone https://github.com/rshun/keyMaster.git
" >>rshun.sh

chmod 777 rshun.sh
mv rshun.sh /home/rshun
su - rshun -c "sh /home/rshun/rshun.sh"
su - rshun -c "rm /home/rshun/rshun.sh"
