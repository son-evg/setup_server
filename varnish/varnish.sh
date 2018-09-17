#!/bin/bash
#######################################################
yum install jemalloc
wget https://raw.githubusercontent.com/keta124/setup_server/master/varnish/varnish.repo -O /etc/yum.repos.d/varnish.repo
yum install varnish git automake libtool.x86_64 python-docutils varnish-libs-devel.x86_64 mhash-devel –y
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

cat >"/etc/sysctl.conf" <<END
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

wget https://raw.githubusercontent.com/keta124/setup_server/master/varnish/varnishncsa.service -O /usr/lib/systemd/system/varnishncsa.service

systemctl deamon-reload
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
