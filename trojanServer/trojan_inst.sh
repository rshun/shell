#!/bin/bash
##################################################
#
#
#功能: 一键安装Tronjan
#
#环境: CentOS8
#
#前提: 先准备好SSL的证书及伪装的网站文件
#
#输入 
#1 证书文件名 
#2 trojan的版本号 
#3 伪装的网站的文件 
#4 trojan的密码及域名
#
#
#自动安装Nginx, 并将侦听端口号改为8443。
#新建 trojan 用户, 使用此用户启动trojan。
#trojan的默认开启CDN，并侦听443端口。
#
##################################################

TrojanPath="/home/trojan"
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
    useradd -d $TrojanPath -m -G certuser trojan
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

uninstall_trojan()
{
rm -rf $TrojanPath
rm -rf $filename
}

install_trojan()
{
yum install unzip tar -y
address="https://github.com/trojan-gfw/trojan/releases/download/v"$version"/"$filename
wget $address

if [ ! -f $filename ]
then 
	echo $filename" is not exist"
	uninstall_nginx
	exit 1
fi

tar -xf $filename -C /home

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

config_trojan()
{
echo "{
    \"run_type\": \"server\",
    \"local_addr\": \"0.0.0.0\",
    \"local_port\": 443,
    \"remote_addr\": \"127.0.0.1\",
    \"remote_port\": 8443,
    \"password\": [
        \""$password"\"
    ],
    \"log_level\": 1,
    \"ssl\": {
        \"cert\": \""$SSLCert"\",
        \"key\": \""$SSLKey"\",
        \"key_password\": \"\",
        \"cipher\": \"ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384\",
        \"cipher_tls13\": \"TLS_AES_128_GCM_SHA256:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_256_GCM_SHA384\",
        \"prefer_server_cipher\": true,
        \"alpn\": [
            \"http/1.1\"
        ],
        \"alpn_port_override\": {
            \"h2\": 81
        },
        \"reuse_session\": true,
        \"session_ticket\": false,
        \"session_timeout\": 600,
        \"plain_http_response\": \"\",
        \"curves\": \"\",
        \"dhparam\": \"\"
    },
    \"tcp\": {
        \"prefer_ipv4\": false,
        \"no_delay\": true,
        \"keep_alive\": true,
        \"reuse_port\": false,
        \"fast_open\": true,
        \"fast_open_qlen\": 20
    },
    \"mysql\": {
        \"enabled\": false,
        \"server_addr\": \"127.0.0.1\",
        \"server_port\": 3306,
        \"database\": \"trojan\",
        \"username\": \"trojan\",
        \"password\": \"\",
        \"cafile\": \"\"
    }
}">$TrojanPath/config.json
cp $TrojanPath/trojan /usr/bin

#生成自启动的服务文件
echo "[Unit]
Description=trojan
Documentation=man:trojan(1) https://trojan-gfw.github.io/trojan/config https://trojan-gfw.github.io/trojan/
After=network.target network-online.target nss-lookup.target mysql.service mariadb.service mysqld.service

[Service]
Type=simple
StandardError=journal
User=trojan
AmbientCapabilities=CAP_NET_BIND_SERVICE
ExecStart=/usr/bin/trojan -c "$TrojanPath"/config.json
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure
RestartSec=1s

[Install]
WantedBy=multi-user.target
">$TrojanPath/trojan.service

cp $TrojanPath/trojan.service /etc/systemd/system

#赋予trojan侦听1024以下的端口
setcap 'CAP_NET_BIND_SERVICE=+eip' /usr/bin/trojan

chown -R trojan:certuser $CertDir
chown -R trojan:certuser $TrojanPath

chmod -R 750 $CertDir

systemctl daemon-reload
systemctl enable trojan
systemctl start trojan
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

#trojan版本号
echo -n "input trojan version:"
read version
filename="trojan-"$version"-linux-amd64.tar.xz"

#html
echo -n "input website zip(include .zip):"
read Website

echo -n "input trojan password:"
read password

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

echo "install trojan....."
install_trojan

echo "nginx is install end,configure nginx...."
config_nginx

echo "configure trojan..."
config_trojan

echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sysctl -p
echo "All is install finish."
