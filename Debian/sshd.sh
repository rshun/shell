config_file="/etc/ssh/sshd_config"

cp $config_file $config_file".bak"

echo "HostKeyAlgorithms +ssh-rsa"  >>$config_file
echo "PubkeyAcceptedKeyTypes +ssh-rsa"  >>$config_file
echo "KexAlgorithms curve25519-sha256@libssh.org,ecdh-sha2-nistp256,ecdh-sha2-nistp384,ecdh-sha2-nistp521,diffie-hellman-group14-sha1" >>$config_file

sed -i -e '/^#PermitRootLogin/s/^#//' -e '/^PermitRootLogin/s/yes/no/' "$config_file"

if [ $# -eq 0 ]
then
    sshPort=39281

else
    sshPort=$1
fi

# 注释掉已有的 Port 行（如 Port 3333）
if grep -q "^Port [0-9]\+" "$config_file"; then
    sed -i 's/^Port [0-9]\+/#&/' "$config_file"
fi

# 新增端口到文件
if ! grep -q "^Port $sshPort" "$config_file"; then
    echo "Port $sshPort" >> "$config_file"
    echo "Port $sshPort has been added to $config_file"
fi

systemctl restart ssh