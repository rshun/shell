install()
{
apt install -y debian-keyring debian-archive-keyring apt-transport-https curl
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' |  gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' |  tee /etc/apt/sources.list.d/caddy-stable.list
apt update
apt install caddy
}

getip()
{
# 提取物理网卡名称（如 ens33）
INTERFACE=$(ip route get 1 | awk '{print $5; exit}')

# 获取本机IP和CIDR（如 192.168.1.129/24）
IP_CIDR=$(ip -o -f inet addr show $INTERFACE | awk '{print $4}')

# 计算局域网网段（如 192.168.1.0/25）
LAN_SUBNET=$(echo $IP_CIDR | awk -F '.' '{print $1"."$2"."$3".0"}' | cut -d'/' -f1)/25
}

openfilewall()
{
ufw allow from "$LAN_SUBNET" to any port 80
ufw reload
}

install
getip
openfilewall