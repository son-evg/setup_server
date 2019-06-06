echo "SSH key"
mkdir -p ~/.ssh
chmod 700 ~/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC2IRyRs0wK/9uMjJt7ZxX8Rb8VDnrCzhHwkykqLtjCyidm0xZrdbOM2X4U6TjDl8G2hp3ZZ2lamBVYCiv9IfjADzQfuhxfHnj+6ORMe8LVDXTd4HkEurnk28UYzkNq0qZekKkMAdQi3GQWmcauOXGLL/9gfTwRwxE7repBXXIWB5h0ye6KZs1hhNGBiWNwxyZotyLHS6JxpD0dBQlWlzAtPcCDCifgxwoue1jTHQ0Ll+kUgdeJbxYRB3GSoHl2rleTJwOxUBhbivG3VsY0eNlr0HWxfIuYBvIgZFfOKEkLAz1gefo131otXwuiWSVJwYtcPuv2RRvWkMQhJXSIieMk5IuAZqYGpwUc5dUj3UhmDGPqzQRvTUWqtDW6LJsAifJnlU1/3Oj0xNRTDDrXF76MQNWWOx6oGUh31gwq04MIsoAWYxzFaFUUOaz9HnYvzlfHQYsdEnBOTxfGiA4JkGDmRrQPT/6Fmb53tLiTVvKHuYbLlalh9XY49jiDkRAbnzxiQfcEf3QV6i8xgXLI4sIgEsfv9AwcvXEMgm6U8RbRqAUIQVpD1DZ+ojZ5h0ZxG6Rh4+vOE/QlRccW5eE/HwUCXkQX7lILxvLjLoELV/StIO0WGR5rBZNPBNC+lW/Nux7At8I6s3FqwdNLo3cHle8I39Kx/TFDDIgRYxp3mHAi+Q==" >> ~/.ssh/authorized_keys
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCywaK0rh9bFxmbFXCP+deiCQFjiMEvvE715NeyuKvg8WBk1jF1EsOf2xsHMTQkrylztcjEOj+sNvIyCRoqDHs2690Sq19v7H8NT0HEDG/sRRmF5NIq/pRQ0Z6Ven0KQSrx2DagnPc63CtO1bkrh+32KwkuLasCMLy4cxDackawHQ19Gvr0330skzdemHc76rB6HNY6kmAbhNH2eK3TRfP4ffmbGIHbKBwjKvv5+phCwQxGOn8RpV9OtFupgXE7/mPxz+wPEzgl+rze+ACunWpinIZh9kkXsUVoghMq6s8XwbyIxQwUx14ilX3EpAvWT9CRncUChfudnAR8xmeuWTuh" >> ~/.ssh/authorized_keys
chmod 644 ~/.ssh/authorized_keys

echo "Securing root Logins"
echo "tty1" > /etc/securetty
chmod 700 /root
echo umask 0022 >> /etc/profile
apt-get update
#apt-get dist-upgrade -y
apt-get install iptables iptables-persistent net-tools htop glances curl ntp wget telnet -y
echo "EDIT SYSCTL"
echo "fs.file-max = 4587520" >>/etc/sysctl.conf
echo "net.core.somaxconn= 2048" >>/etc/sysctl.conf
echo "net.ipv6.conf.all.disable_ipv6 = 1" >>/etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" >>/etc/sysctl.conf
echo "net.ipv6.conf.lo.disable_ipv6 = 1" >>/etc/sysctl.conf
echo "net.ipv4.tcp_syncookies = 1" >>/etc/sysctl.conf
echo "vm.swappiness=1" >>/etc/sysctl.conf
echo "net.ipv4.tcp_timestamps=0" >>/etc/sysctl.conf
echo "net.ipv4.tcp_sack=1" >>/etc/sysctl.conf
echo "net.core.netdev_max_backlog=250000" >>/etc/sysctl.conf
echo "net.core.rmem_max=4194304" >>/etc/sysctl.conf
echo "net.core.wmem_max=4194304" >>/etc/sysctl.conf
echo "net.core.rmem_default=4194304" >>/etc/sysctl.conf
echo "net.core.optmem_max=4194304" >>/etc/sysctl.conf
echo "net.ipv4.tcp_rmem="4096 87380 4194304"" >>/etc/sysctl.conf
echo "net.ipv4.tcp_wmem="4096 65536 4194304"" >>/etc/sysctl.conf
echo "net.ipv4.tcp_low_latency=1" >>/etc/sysctl.conf
echo "net.ipv4.tcp_adv_win_scale=1" >>/etc/sysctl.conf
sysctl -p

echo "EDIT LIMITS.CONF"
echo "* soft nofile 65536" >>/etc/security/limits.conf
echo "* soft nproc 65536" >>/etc/security/limits.conf
echo "* hard nofile 1048576" >>/etc/security/limits.conf
echo "* hard nproc unlimited" >>/etc/security/limits.conf
echo "* hard core 0" >>/etc/security/limits.conf
#echo "root soft nofile 65536" >>/etc/security/limits.conf
#echo "root soft nproc 65536" >>/etc/security/limits.conf
#echo "root hard nofile 1048576" >>/etc/security/limits.conf
#echo "root hard nproc unlimited" >>/etc/security/limits.conf
echo "root - memlock unlimited" >>/etc/security/limits.conf

echo "ENABLE HUGEPAGE"
sed -i -e 's/exit 0//g' /etc/rc.local
echo "echo never > /sys/kernel/mm/transparent_hugepage/enabled" >> /etc/rc.local
echo "echo never > /sys/kernel/mm/transparent_hugepage/defrag" >>/etc/rc.local
echo "exit 0" >>/etc/rc.local
chmod +x /etc/rc.local

systemctl enable rsyslog.service
systemctl start rsyslog.service
echo "SET TIMEZONE"
timedatectl set-timezone Asia/Ho_Chi_Minh
systemctl enable netfilter-persistent cron
ufw disable
#iptables
iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A INPUT -p icmp -j ACCEPT
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -p tcp -m state --state NEW -m tcp --dport 22 -j ACCEPT
iptables -A INPUT -j REJECT --reject-with icmp-host-prohibited
iptables -A FORWARD -j REJECT --reject-with icmp-host-prohibited
netfilter-persistent save
netfilter-persistent reload
#ntp
sed -i -e 's/pool 0.ubuntu.pool.ntp.org iburst/server time.google.com iburst/g' /etc/ntp.conf
systemctl start ntp
systemctl enable ntp
#cmdlog
echo "export PROMPT_COMMAND='RETRN_VAL=$?;logger -p local6.debug \"[\$(echo \$SSH_CLIENT | cut -d\" \" -f1)] # \$(history 1 | sed \"s/^[ ]*[0-9]\+[ ]*//\" )\"'" >>/etc/bash.bashrc
echo "local6.debug                /var/log/cmdlog.log" >> /etc/rsyslog.conf
>/var/log/cmdlog.log
chown -R syslog:adm /var/log/cmdlog.log
service rsyslog restart
echo "/var/log/cmdlog.log {
  create 0644 syslog adm
  compress
  weekly
  rotate 12
  sharedscripts
  postrotate
  /bin/kill -HUP \`cat /var/run/syslogd.pid 2> /dev/null\` 2> /dev/null || true
  endscript
}" >>/etc/logrotate.d/cmdlog
