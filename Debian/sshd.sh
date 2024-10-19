echo "HostKeyAlgorithms +ssh-rsa"  >>/etc/ssh/sshd_config
echo "PubkeyAcceptedKeyTypes +ssh-rsa"  >>/etc/ssh/sshd_config
echo "KexAlgorithms curve25519-sha256@libssh.org,ecdh-sha2-nistp256,ecdh-sha2-nistp384,ecdh-sha2-nistp521,diffie-hellman-group14-sha1" >>/etc/ssh/sshd_config
echo "PermitRootLogin no" >>/etc/ssh/sshd_config
if [ $# -eq 0 ]
then
    echo "Port 39281" >>/etc/ssh/sshd_config
else
    echo "Port $1" >>/etc/ssh/sshd_config
fi
systemctl restart ssh