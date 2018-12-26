echo "SSH key"
mkdir -p ~/.ssh
chmod 700 ~/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC2IRyRs0wK/9uMjJt7ZxX8Rb8VDnrCzhHwkykqLtjCyidm0xZrdbOM2X4U6TjDl8G2hp3ZZ2lamBVYCiv9IfjADzQfuhxfHnj+6ORMe8LVDXTd4HkEurnk28UYzkNq0qZekKkMAdQi3GQWmcauOXGLL/9gfTwRwxE7repBXXIWB5h0ye6KZs1hhNGBiWNwxyZotyLHS6JxpD0dBQlWlzAtPcCDCifgxwoue1jTHQ0Ll+kUgdeJbxYRB3GSoHl2rleTJwOxUBhbivG3VsY0eNlr0HWxfIuYBvIgZFfOKEkLAz1gefo131otXwuiWSVJwYtcPuv2RRvWkMQhJXSIieMk5IuAZqYGpwUc5dUj3UhmDGPqzQRvTUWqtDW6LJsAifJnlU1/3Oj0xNRTDDrXF76MQNWWOx6oGUh31gwq04MIsoAWYxzFaFUUOaz9HnYvzlfHQYsdEnBOTxfGiA4JkGDmRrQPT/6Fmb53tLiTVvKHuYbLlalh9XY49jiDkRAbnzxiQfcEf3QV6i8xgXLI4sIgEsfv9AwcvXEMgm6U8RbRqAUIQVpD1DZ+ojZ5h0ZxG6Rh4+vOE/QlRccW5eE/HwUCXkQX7lILxvLjLoELV/StIO0WGR5rBZNPBNC+lW/Nux7At8I6s3FqwdNLo3cHle8I39Kx/TFDDIgRYxp3mHAi+Q== " >> ~/.ssh/authorized_keys
chmod 644 ~/.ssh/authorized_keys

echo "Securing root Logins"
echo "tty1" > /etc/securetty
chmod 700 /root

echo "DISABLE FIREWALL, POSTFIX"
systemctl disable firewalld
systemctl disable postfix
systemctl disable chrony

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
#echo "net.core_wmem_default=4194304" >>/etc/sysctl.conf
echo "net.core.optmem_max=4194304" >>/etc/sysctl.conf
echo "net.ipv4.tcp_rmem="4096 87380 4194304"" >>/etc/sysctl.conf
echo "net.ipv4.tcp_wmem="4096 65536 4194304"" >>/etc/sysctl.conf
echo "net.ipv4.tcp_low_latency=1" >>/etc/sysctl.conf
echo "net.ipv4.tcp_adv_win_scale=1" >>/etc/sysctl.conf
sysctl -p

echo "EDIT LIMITS.CONF"
echo "* hard core 0" >>/etc/security/limits.conf
echo "root soft nofile 32768" >>/etc/security/limits.conf
echo "root soft nproc 65536" >>/etc/security/limits.conf
echo "root hard nofile 1048576" >>/etc/security/limits.conf
echo "root hard nproc unlimited" >>/etc/security/limits.conf
echo "root - memlock unlimited" >>/etc/security/limits.conf

echo "ENABLE HUGEPAGE"
echo "if [ -d /sys/kernel/mm/transparent_hugepage ]; then
echo never > /sys/kernel/mm/transparent_hugepage/enabled
fi" >> /etc/rc.d/rc.local

echo "if [ -d /sys/kernel/mm/transparent_hugepage/defrag ]; then
echo never > /sys/kernel/mm/transparent_hugepage/defrag
fi" >>/etc/rc.d/rc.local

echo "INSTALL EPEL-RELEASE"
yum install epel-release -y
yum install  iptables-services net-tools htop glances tuned ntp nscd wget -y
yum groupinstall "Development Tools" -y

echo "INSTALL Rsyslog"
yum -y install rsyslog
systemctl enable rsyslog.service
systemctl start rsyslog.service

echo "SET TIMEZONE"
timedatectl set-timezone Asia/Ho_Chi_Minh

systemctl enable iptables nscd crond ntpd

echo "Update kernel"
yum update kernel -y

echo "EDIT SELINUX"
sed -i -e 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
sed -i -e 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

#cmdlog
echo "export PROMPT_COMMAND='RETRN_VAL=$?;logger -p local6.debug \"[\$(echo \$SSH_CLIENT | cut -d\" \" -f1)] # \$(history 1 | sed \"s/^[ ]*[0-9]\+[ ]*//\" )\"'" >>/etc/bashrc
echo "local6.debug                /var/log/cmdlog.log" >> /etc/rsyslog.conf
>/var/log/cmdlog.log
service rsyslog restart
echo "/var/log/cmdlog.log {
  create 0644 root root
  compress
  weekly
  rotate 12
  sharedscripts
  postrotate
  /bin/kill -HUP \`cat /var/run/syslogd.pid 2> /dev/null\` 2> /dev/null || true
  endscript
}" >>/etc/logrotate.d/cmdlog
