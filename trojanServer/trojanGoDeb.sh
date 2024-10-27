#!/bin/bash
##################################################
#
#
#功能: 一键安装Tronjan-go
#
#环境: Debian12
#
#前提: 先准备好SSL的证书及伪装的网站文件
#
#输入 
#1 证书文件名 
#2 Trojan-Go的版本号 
#3 伪装的网站的文件 
#4 Trojan-Go的密码及域名
#
#
#自动安装Nginx
#新建 trojan 用户, 使用此用户启动trojan。
#trojan-Go的默认开启CDN，并侦听443端口。
#
##################################################
TrojanGoUser="trojango"
TrojanGoPath="/home/"$TrojanGoUser
CertDir="/etc/certs"

toadduser()
{
#新建证书用户组
certgroup=`cat /etc/group|grep certuser|wc -l`
if [ $certgroup -eq 0 ]
then
    groupadd certuser
fi

num=`cat /etc/passwd|grep "$TrojanGoUser"|wc -l`
if [ $num -eq 0 ]
then
    useradd -d $TrojanGoPath -s /bin/bash -m -G certuser $TrojanGoUser
fi
}

uninstall_nginx()
{
systemctl stop nginx
systemctl stop ufw
systemctl disable nginx
systemctl disable ufw

ufw deny 'Nginx Full'

apt remove ufw -y
apt remove nginx -y
}

uninstall_trojango()
{
rm -rf $TrojanGoPath
rm -rf trojan-go-linux-amd64.zip
}

install_trojango()
{
apt install unzip -y
address="https://github.com/p4gefau1t/trojan-go/releases/download/v"$version"/trojan-go-linux-amd64.zip"
wget $address

if [ ! -f trojan-go-linux-amd64.zip ]
then 
    echo "trojan-go-linux-amd64.zip is not exist"
    uninstall_nginx
    exit 1
fi

unzip trojan-go-linux-amd64.zip -d $TrojanGoPath
}

install_nginx()
{
apt install nginx -y
apt install ufw -y

systemctl enable nginx
ufw allow 'Nginx Full'
ufw reload
}

config_nginx()
{
rm -rf /etc/nginx/sites-enabled/default

echo "server {
        listen 80 default_server;
        listen [::]:80 default_server;
        server_name  $Domain;

        # SSL certificate configuration
        ssl_certificate \""$SSLCert"\";
        ssl_certificate_key \""$SSLKey"\";
        ssl_session_cache shared:SSL:1m;
        ssl_session_timeout  10m;
        ssl_prefer_server_ciphers on;

        # SSL Protocols
        ssl_protocols TLSv1.2 TLSv1.3;

        # Root directory and default index file
        root /var/www/html;
        index index.html;

        # Add some common security headers
        add_header Strict-Transport-Security \"max-age=31536000; includeSubDomains\" always;
        add_header X-Frame-Options DENY;
        add_header X-Content-Type-Options nosniff;
    
        # Load configuration files for the default server block.
        include /etc/nginx/default.d/*.conf;

        location / {
            try_files $uri $uri/ =404;
        }

        error_page 404 /404.html;
            location = /40x.html {
            internal;
        }

        error_page 500 502 503 504 /50x.html;
            location = /50x.html {
            internal;
        }
    }
" >>"/etc/nginx/sites-available/"$Domain".conf"
ln -s "/etc/nginx/sites-available/"$Domain".conf" "/etc/nginx/sites-enabled/"$Domain".conf"
nginx -s reload
rm -rf /var/www/html
unzip $Website -d /var/www/html
}

config_trojango()
{
echo "{
    \"run_type\": \"server\",
    \"local_addr\": \"0.0.0.0\",
    \"local_port\": 443,
    \"remote_addr\": \"127.0.0.1\",
    \"remote_port\": 80,
    \"password\": [
        \""$password"\"
    ],
    \"ssl\": {
        \"verify\": true,
        \"verify_hostname\": true,
        \"fallback_port\": 8443,
        \"cert\": \""$SSLCert"\",
        \"key\": \""$SSLKey"\",
        \"sni\": \""x.$Domain"\"
    },
    \"router\": {
        \"enabled\": true,
        \"block\": [
            \"geoip:private\"
        ],
        \"geoip\": \"$TrojanGoPath"/geoip.dat"\",
        \"geosite\": \"$TrojanGoPath"/geosite.dat"\"
    },
 \"websocket\": {
    \"enabled\": true,
    \"path\": \"/polarbear\",
    \"host\": \""x.$Domain"\"
  }
}" >>$TrojanGoPath/server.json
cp $TrojanGoPath/trojan-go /usr/bin

#生成自启动的服务文件
echo "[Unit]
Description=Trojan-Go - An unidentifiable mechanism that helps you bypass GFW
Documentation=https://p4gefau1t.github.io/trojan-go/
After=network.target nss-lookup.target

[Service]
User="$TrojanGoUser"
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/bin/trojan-go -config "$TrojanGoPath"/server.json
Restart=on-failure
RestartSec=10s
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target
" >$TrojanGoPath/trojan-go.service

cp $TrojanGoPath/trojan-go.service /etc/systemd/system

#赋予trojan-go侦听1024以下的端口
setcap 'CAP_NET_BIND_SERVICE=+eip' /usr/bin/trojan-go

chown -R $TrojanGoUser:certuser $CertDir
chown -R $TrojanGoUser:certuser $TrojanGoPath

chmod -R 750 $CertDir

systemctl daemon-reload
systemctl enable trojan-go
systemctl start trojan-go
}

################################################################################
#
#
#脚本从此处执行
#
################################################################################
#新建trojan用户
toadduser

#cert证书文件名
echo -n "input ssl cert's filename:"
read SSLCertFile

#key证书文件名
echo -n "input ssl key's filename:"
read SSLKeyFile

if [ ! -f $SSLCertFile ]
then
    echo $SSLCertFile" is not exist..."
    exit 1
fi

if [ ! -f $SSLKeyFile ]
then
    echo $SSLKeyFile" is not exist..."
    exit 1
fi

#trojan-go版本号
#echo -n "input trojan-go version:"
#read version
version=0.10.6

#html
#echo -n "input website zip(include .zip):"
#read Website
Website=html.zip

echo -n "input trojan-go password:"
read password

echo -n "input domain(include suffix google.com):"
read Domain

if [  ! -f $Website ]
then
    echo $Website" is not exist..."
    exit 1
fi

mkdir -p $CertDir
cp $SSLCertFile $CertDir
cp $SSLKeyFile $CertDir
if [ ${CertDir: 0-1: 1} == "/" ]
then
    SSLCert=$CertDir$SSLCertFile
    SSLKey=$CertDir$SSLKeyFile
else
    SSLCert=$CertDir"/"$SSLCertFile
    SSLKey=$CertDir"/"$SSLKeyFile
fi 


#安装nginx
echo "install nginx......"
install_nginx

echo "install trojan-go....."
install_trojango

echo "nginx is install end,configure nginx...."
config_nginx

echo "configure trojan-go..."
config_trojango

echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sysctl -p

echo "All install is finish."
