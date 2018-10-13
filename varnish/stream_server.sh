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

echo "EDIT SYSCTL"

cat >"/etc/sysctl.conf" <<END
fs.file-max = 4587520
net.core.somaxconn= 2048
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
net.ipv4.tcp_syncookies = 1
vm.swappiness=0
vm.overcommit_memory=1
net.ipv4.tcp_mem = 10240 87380 134217728
net.ipv4.tcp_rmem = 10240 87380 134217728
net.ipv4.tcp_wmem = 10240 87380 134217728
net.ipv4.tcp_max_syn_backlog = 204800
net.ipv4.ip_local_port_range = 20000 65535
net.ipv4.tcp_fin_timeout = 10
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_max_tw_buckets = 2440000
net.nf_conntrack_max = 10000000
net.ipv4.tcp_timestamps = 0
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.core.rmem_default = 16777216
net.core.wmem_default = 16777216
net.core.optmem_max = 134217728
net.ipv4.tcp_moderate_rcvbuf =1
net.ipv4.tcp_congestion_control=htcp
net.ipv4.tcp_mtu_probing = 1
net.ipv4.ip_nonlocal_bind = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_dsack = 1
net.core.netdev_budget = 600
net.ipv4.tcp_low_latency = 1
net.ipv4.tcp_window_scaling = 1
net.core.netdev_max_backlog = 300000
END
sysctl -p

echo "EDIT LIMITS.CONF"
echo "* hard core 0" >>/etc/security/limits.conf
echo "root soft nofile 32768" >>/etc/security/limits.conf
echo "root soft nproc 65536" >>/etc/security/limits.conf
echo "root hard nofile 1048576" >>/etc/security/limits.conf
echo "root hard nproc unlimited" >>/etc/security/limits.conf
echo "root - memlock unlimited" >>/etc/security/limits.conf

echo "ENABLE HUGEPAGE"
echo "if test -f /sys/kernel/mm/transparent_hugepage/enabled; then
echo never > /sys/kernel/mm/transparent_hugepage/enabled
fi" >> /etc/rc.d/rc.local

echo "if test -f /sys/kernel/mm/transparent_hugepage/defrag; then
echo never > /sys/kernel/mm/transparent_hugepage/defrag
fi" >>/etc/rc.d/rc.local

echo "INSTALL EPEL-RELEASE"
yum install epel-release -y
yum install  iptables-services net-tools htop glances tuned chrony wget bind-utils -y
yum groupinstall "Development Tools" -y

echo "INSTALL Rsyslog"
yum -y install rsyslog
systemctl enable rsyslog.service
systemctl start rsyslog.service

echo "SET TIMEZONE"
timedatectl set-timezone Asia/Ho_Chi_Minh

systemctl enable iptables chronyd crond tuned
systemctl start chronyd
chronyc tracking

echo "Update kernel"
yum update kernel -y

echo "IF RUN TUNED ==> "
echo "tuned-adm profile throughput-performance"
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

yum install jemalloc -y
wget https://raw.githubusercontent.com/keta124/setup_server/master/varnish/varnish.repo -O /etc/yum.repos.d/varnish.repo
yum install varnish git automake libtool.x86_64 python-docutils varnish-libs-devel.x86_64 mhash-devel -y
printf "Load varnish.params  \n"
wget https://raw.githubusercontent.com/keta124/setup_server/master/varnish/varnish.params -O /etc/varnish/varnish.params

printf "Install libvmod-digest- computing HMAC, message digests and working with base64 \n"
cd /usr/src/
git clone https://github.com/varnish/libvmod-digest.git
cd libvmod-digest
yum install python-docutils
./autogen.sh
./configure
make -j 4
make install

printf "Install GeoIP \n"
yum install geoip geoip-devel -y
cd /usr/share/GeoIP/
mv GeoIP.dat GeoIP.dat.old
wget -O GeoIP.dat.gz http://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz
gunzip GeoIP.dat.gz
cd /usr/src/
git clone https://github.com/varnish/libvmod-geoip
cd libvmod-geoip
./autogen.sh
./configure
make
make install

mkdir -p /var/www/html/errors/

cat > "/var/www/html/errors/503.html" <<END
<html>
<head><title>503 Service Unavailable</title></head>
<body bgcolor="white">
<center><h1>503 Service Unavailable</h1></center>
<hr><center>Nginx</center>
</body>
</html>
<!-- a padding to disable MSIE and Chrome friendly error page -->
<!-- a padding to disable MSIE and Chrome friendly error page -->
<!-- a padding to disable MSIE and Chrome friendly error page -->
<!-- a padding to disable MSIE and Chrome friendly error page -->
<!-- a padding to disable MSIE and Chrome friendly error page -->
<!-- a padding to disable MSIE and Chrome friendly error page -->
END

cat > "/var/www/html/errors/500.html" <<END
<html>
<head><title>500 Internal Server Error</title></head>
<body bgcolor="white">
<center><h1>500 Internal Server Error</h1></center>
<hr><center>Nginx</center>
</body>
</html>
<!-- a padding to disable MSIE and Chrome friendly error page -->
<!-- a padding to disable MSIE and Chrome friendly error page -->
<!-- a padding to disable MSIE and Chrome friendly error page -->
<!-- a padding to disable MSIE and Chrome friendly error page -->
<!-- a padding to disable MSIE and Chrome friendly error page -->
<!-- a padding to disable MSIE and Chrome friendly error page -->
END

cat > "/var/www/html/errors/403.html" <<END
<html>
<head><title>403 Forbidden</title></head>
<body bgcolor="white">
<center><h1>403 Forbidden</h1></center>
<hr><center>Nginx</center>
</body>
</html>
<!-- a padding to disable MSIE and Chrome friendly error page -->
<!-- a padding to disable MSIE and Chrome friendly error page -->
<!-- a padding to disable MSIE and Chrome friendly error page -->
<!-- a padding to disable MSIE and Chrome friendly error page -->
<!-- a padding to disable MSIE and Chrome friendly error page -->
<!-- a padding to disable MSIE and Chrome friendly error page -->
END
cat > "/var/www/html/errors/429.html" <<END
<html>
<head><title>429 TOO MANY REQUESTS</title></head>
<body bgcolor="white">
<center><h1>429 TOO MANY REQUESTS</h1></center>
<hr><center>Nginx</center>
</body>
</html>
<!-- a padding to disable MSIE and Chrome friendly error page -->
<!-- a padding to disable MSIE and Chrome friendly error page -->
<!-- a padding to disable MSIE and Chrome friendly error page -->
<!-- a padding to disable MSIE and Chrome friendly error page -->
<!-- a padding to disable MSIE and Chrome friendly error page -->
<!-- a padding to disable MSIE and Chrome friendly error page -->
END

cat > "/var/www/html/errors/477.html" <<END
<html>
<head><title>477 Suspended CDN resource</title></head>
<body bgcolor="white">
<center><h1>477 Suspended CDN resource</h1></center>
<hr><center>Nginx</center>
</body>
</html>
<!-- a padding to disable MSIE and Chrome friendly error page -->
<!-- a padding to disable MSIE and Chrome friendly error page -->
<!-- a padding to disable MSIE and Chrome friendly error page -->
<!-- a padding to disable MSIE and Chrome friendly error page -->
<!-- a padding to disable MSIE and Chrome friendly error page -->
<!-- a padding to disable MSIE and Chrome friendly error page -->
END

wget https://raw.githubusercontent.com/keta124/setup_server/master/varnish/varnishncsa.service -O /usr/lib/systemd/system/varnishncsa.service

systemctl daemon-reload
systemctl enable varnish

printf "Config Varnish \n"
mkdir -p /etc/varnish/conf.d/
cd /etc/varnish/

cat > "/etc/varnish/default.vcl" <<END
vcl 4.0;
import digest;
import std;
import directors;
import geoip;
include "all-vhosts.vcl";
include "main.vcl";
END
echo "include \"/etc/varnish/conf.d/1000.vcl\";" > /etc/varnish/all-vhosts.vcl

wget https://raw.githubusercontent.com/keta124/setup_server/master/varnish/main.vcl -O /etc/varnish/main.vcl
wget https://raw.githubusercontent.com/keta124/setup_server/master/varnish/1000.vcl -O /etc/varnish/conf.d/1000.vcl
