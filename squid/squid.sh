yum install squid httpd-tools -y
htpasswd -b -c /etc/squid/passwd admin Admin@1123##
chown -R squid:squid /etc/squid/passwd
wget https://raw.githubusercontent.com/keta124/setup_server/master/squid/squid.conf -O /etc/squid/squid.conf
systemctl enable squid
systemctl start squid
echo "Edit iptables open port 3800"
