chmod 644 ~/.ssh/authorized_keys

echo "DISABLE FIREWALL, POSTFIX"
systemctl disable firewalld
systemctl disable postfix

echo "EDIT SYSCTL"
echo "net.core.somaxconn=2048" >>/etc/sysctl.conf
echo "net.ipv6.conf.all.disable_ipv6 = 1" >>/etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" >>/etc/sysctl.conf
echo "net.ipv6.conf.lo.disable_ipv6 = 1" >>/etc/sysctl.conf
echo "net.ipv4.tcp_syncookies = 1" >>/etc/sysctl.conf
echo "vm.swappiness=0" >>/etc/sysctl.conf
echo "vm.overcommit_memory=1" >>/etc/sysctl.conf
sysctl -p

echo "EDIT LIMITS.CONF"
echo "* soft nofile 32768" >>/etc/security/limits.conf
echo "* soft nproc 65536" >>/etc/security/limits.conf
echo "* hard nofile 1048576" >>/etc/security/limits.conf
echo "* hard nproc unlimited" >>/etc/security/limits.conf
echo "* hard memlock unlimited" >>/etc/security/limits.conf
echo "* soft memlock unlimited" >>/etc/security/limits.conf

echo "ENABLE HUGEPAGE"
echo "if test -f /sys/kernel/mm/transparent_hugepage/enabled; then
echo never > /sys/kernel/mm/transparent_hugepage/enabled
fi" >> /etc/rc.d/rc.local

echo "if test -f /sys/kernel/mm/transparent_hugepage/defrag; then
echo never > /sys/kernel/mm/transparent_hugepage/defrag
fi" >>/etc/rc.d/rc.local

echo "INSTALL EPEL-RELEASE"
yum install epel-release -y
yum install  iptables-services net-tools htop glances tuned chrony -y
yum groupinstall "Development Tools" -y

echo "SET TIMEZONE"
timedatectl set-timezone Asia/Ho_Chi_Minh

systemctl enable iptables chronyd crond tuned
systemctl start chronyd
chronyc tracking

echo "IF RUN TUNED ==> "
echo "tuned-adm profile throughput-performance"
echo "EDIT SELINUX"
sed -i -e 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
