#!/bin/bash
##################################################
#
#
#功能: 一键安装Tronjan-go
#
#环境: CentOS8
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
#自动安装Nginx, 并将侦听端口号改为8443。
#新建 trojan 用户, 使用此用户启动trojan。
#trojan-Go的默认开启CDN，并侦听443端口。
#
##################################################

TrojanGoPath="/home/trojan"
CertDir="/etc/certs"

toadduser()
{
#新建证书用户组
certgroup=`cat /etc/group|grep certuser|wc -l`
if [ $certgroup -eq 0 ]
then
    groupadd certuser
fi

num=`cat /etc/passwd|grep trojan|wc -l`
if [ $num -eq 0 ]
then
    useradd -d $TrojanGoPath -m -G certuser trojan
fi
}

uninstall_nginx()
{
systemctl stop nginx
firewall-cmd --permanent --zone=public --remove-service=http
firewall-cmd --permanent --zone=public --remove-service=https
firewall-cmd --reload

systemctl disable nginx
yum remove nginx -y
}

uninstall_trojango()
{
rm -rf $TrojanGoPath"/trojan-go"
rm -rf trojan-go-linux-amd64.zip
}

install_trojango()
{
yum install unzip -y
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
yum install nginx -y
systemctl enable nginx

firewall-cmd --permanent --zone=public --add-service=http
firewall-cmd --permanent --zone=public --add-service=https
firewall-cmd --reload
}

config_nginx()
{
cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.old
#文件倒数第二行有{，先将其删除再补
sed -i '$d' /etc/nginx/nginx.conf
sed -i '$d' /etc/nginx/nginx.conf

echo "        server {
        listen       8443 ssl http2 default_server;
        listen       [::]:8443 ssl http2 default_server;
        server_name  _;
        root         /usr/share/nginx/html;

        ssl_certificate \""$SSLCert"\";
        ssl_certificate_key \""$SSLKey"\";
        ssl_session_cache shared:SSL:1m;
        ssl_session_timeout  10m;
        ssl_ciphers PROFILE=SYSTEM;
        ssl_prefer_server_ciphers on;

        # Load configuration files for the default server block.
        include /etc/nginx/default.d/*.conf;

        location / {
        }

        error_page 404 /404.html;
            location = /40x.html {
        }

        error_page 500 502 503 504 /50x.html;
            location = /50x.html {
        }
    }
}
" >>/etc/nginx/nginx.conf
setenforce 0
systemctl restart nginx
rm -rf /usr/share/nginx/html
unzip $Website -d /usr/share/nginx
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
        \"sni\": \""$Domain"\"
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
    \"host\": \""$Domain"\"
  }
}" >>$TrojanGoPath/server.json
cp $TrojanGoPath/trojan-go /usr/bin

#生成自启动的服务文件
echo "[Unit]
Description=Trojan-Go - An unidentifiable mechanism that helps you bypass GFW
Documentation=https://p4gefau1t.github.io/trojan-go/
After=network.target nss-lookup.target

[Service]
User=trojan
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

chown -R trojan:certuser $CertDir
chown -R trojan:certuser $TrojanGoPath

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
echo -n "input trojan-go version:"
read version

#html
echo -n "input website zip(include .zip):"
read Website

echo -n "input trojan-go password:"
read password

echo -n "input domain:"
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

echo "All is install finish."
