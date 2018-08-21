yum clean all
yum -y install gawk bc wget lsof

clear
printf "=========================================================================\n"
printf "Chung ta se kiem tra cac thong so VPS cua ban de dua ra cai dat hop ly \n"
printf "=========================================================================\n"

cpu_name=$( awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo )
cpu_cores=$( awk -F: '/model name/ {core++} END {print core}' /proc/cpuinfo )
cpu_freq=$( awk -F: ' /cpu MHz/ {freq=$2} END {print freq}' /proc/cpuinfo )
server_ram_total=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
server_ram_mb=`echo "scale=0;$server_ram_total/1024" | bc`
server_hdd=$( df -h | awk 'NR==2 {print $2}' )
server_swap_total=$(awk '/SwapTotal/ {print $2}' /proc/meminfo)
server_swap_mb=`echo "scale=0;$server_swap_total/1024" | bc`
server_ip=$(curl -s $script_root/ip/)

printf "=========================================================================\n"
printf "Thong so server cua ban nhu sau \n"
printf "=========================================================================\n"
echo "Loai CPU : $cpu_name"
echo "Tong so CPU core : $cpu_cores"
echo "Toc do moi core : $cpu_freq MHz"
echo "Tong dung luong RAM : $server_ram_mb MB"
echo "Tong dung luong swap : $server_swap_mb MB"
echo "Tong dung luong o dia : $server_hdd GB"
echo "IP cua server la : $server_ip"
printf "=========================================================================\n"
printf "=========================================================================\n"

clear
printf "=========================================================================\n"
printf "Chuan bi qua trinh cai dat... \n"
printf "=========================================================================\n"

printf "Ban hay lua chon phien ban PHP muon su dung:\n"
prompt="Nhap vao lua chon cua ban [1-3]: "
php_version="7.1"; # Default PHP 7.1
options=("PHP 7.1" "PHP 7.0" "PHP 5.6")
PS3="$prompt"
select opt in "${options[@]}"; do 

    case "$REPLY" in
    1) php_version="7.1"; break;;
    2) php_version="7.0"; break;;
    3) php_version="5.6"; break;;
    $(( ${#options[@]}+1 )) ) printf "\nHe thong se cai dat PHP 7.1\n"; break;;
    *) printf "Ban nhap sai, he thong cai dat PHP 7.1\n"; break;;
    esac
    
done

printf "\nNhap vao ten mien or ten thu muc roi an [ENTER]: " 
read server_name
if [ "$server_name" = "" ]; then
	server_name="platfio.com"
	echo "Ban nhap sai, he thong dung platfio.com lam ten mien chinh"
fi

# Install EPEL + Remi Repo
yum -y install epel-release yum-utils
rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-7.rpm

yum-config-manager --enable remi

if [ "$php_version" = "7.1" ]; then
	yum-config-manager --enable remi-php71
	yum -y install nginx php-fpm
	yum -y install php-gd php-mysqlnd php-pdo php-xml php-mbstring php-mcrypt php-curl php-opcache php-cli php-pecl-zip
elif [ "$php_version" = "7.0" ]; then
	yum-config-manager --enable remi-php70
	yum -y install nginx php-fpm
	yum -y install php-gd php-mysqlnd php-pdo php-xml php-mbstring php-mcrypt php-curl php-opcache php-cli php-pecl-zip
elif [ "$php_version" = "5.6" ]; then
	yum-config-manager --enable remi-php56
	yum -y install nginx php-fpm
	yum -y install php-gd php-mysqlnd php-pdo php-xml php-mbstring php-mcrypt php-curl php-opcache php-cli
elif [ "$php_version" = "5.5" ]; then
	yum-config-manager --enable remi-php55
	yum -y install nginx php-fpm
	yum -y install php-gd php-mysqlnd php-pdo php-xml php-mbstring php-mcrypt php-curl php-opcache php-cli
else
	yum -y install php-gd php-mysqlnd php-pdo php-xml php-mbstring php-mcrypt php-curl php-devel php-cli gcc
fi

systemctl enable nginx.service
systemctl enable php-fpm.service

mkdir -p /var/log/nginx /var/log/php-fpm
chown -R nginx:nginx /var/log/nginx
chown -R nginx:nginx /var/lib/php/session
chown -R nginx:nginx /var/log/php-fpm

phplowmem='2097152'
check_phplowmem=$(expr $server_ram_total \< $phplowmem)
max_children=`echo "scale=0;$server_ram_mb*0.4/30" | bc`
if [ "$check_phplowmem" == "1" ]; then
	lessphpmem=y
fi

if [[ "$lessphpmem" = [yY] ]]; then  
	wget -q https://raw.githubusercontent.com/keta124/setup_server/master/lamp/php-fpm/php-fpm-min.conf -O /etc/php-fpm.conf
	wget -q https://raw.githubusercontent.com/keta124/setup_server/master/lamp/php-fpm/www-min.conf -O /etc/php-fpm.d/www.conf
else
	wget -q https://raw.githubusercontent.com/keta124/setup_server/master/lamp/php-fpm/php-fpm.conf -O /etc/php-fpm.conf
	wget -q https://raw.githubusercontent.com/keta124/setup_server/master/lamp/php-fpm/www.conf -O /etc/php-fpm.d/www.conf
fi # lessphpmem

sed -i "s/max_children_here/$max_children/g" /etc/php-fpm.d/www.conf

# dynamic PHP memory_limit calculation
if [[ "$server_ram_total" -le '262144' ]]; then
	php_memorylimit='48M'
	php_uploadlimit='48M'
	php_realpathlimit='256k'
	php_realpathttl='14400'
elif [[ "$server_ram_total" -gt '262144' && "$server_ram_total" -le '393216' ]]; then
	php_memorylimit='96M'
	php_uploadlimit='96M'
	php_realpathlimit='320k'
	php_realpathttl='21600'
elif [[ "$server_ram_total" -gt '393216' && "$server_ram_total" -le '524288' ]]; then
	php_memorylimit='128M'
	php_uploadlimit='128M'
	php_realpathlimit='384k'
	php_realpathttl='28800'
elif [[ "$server_ram_total" -gt '524288' && "$server_ram_total" -le '1049576' ]]; then
	php_memorylimit='160M'
	php_uploadlimit='160M'
	php_realpathlimit='384k'
	php_realpathttl='28800'
elif [[ "$server_ram_total" -gt '1049576' && "$server_ram_total" -le '2097152' ]]; then
	php_memorylimit='256M'
	php_uploadlimit='256M'
	php_realpathlimit='384k'
	php_realpathttl='28800'
elif [[ "$server_ram_total" -gt '2097152' && "$server_ram_total" -le '3145728' ]]; then
	php_memorylimit='320M'
	php_uploadlimit='320M'
	php_realpathlimit='512k'
	php_realpathttl='43200'
elif [[ "$server_ram_total" -gt '3145728' && "$server_ram_total" -le '4194304' ]]; then
	php_memorylimit='512M'
	php_uploadlimit='512M'
	php_realpathlimit='512k'
	php_realpathttl='43200'
elif [[ "$server_ram_total" -gt '4194304' ]]; then
	php_memorylimit='800M'
	php_uploadlimit='800M'
	php_realpathlimit='640k'
	php_realpathttl='86400'
fi

cat > "/etc/php.d/00-custom.ini" <<END
date.timezone = Asia/Ho_Chi_Minh
max_execution_time = 180
short_open_tag = On
realpath_cache_size = $php_realpathlimit
realpath_cache_ttl = $php_realpathttl
memory_limit = $php_memorylimit
upload_max_filesize = $php_uploadlimit
post_max_size = $php_uploadlimit
expose_php = Off
mail.add_x_header = Off
max_input_nesting_level = 128
max_input_vars = 2000
mysqlnd.net_cmd_buffer_size = 16384
always_populate_raw_post_data=-1
disable_functions=shell_exec
END

# Zend Opcache
opcache_path='opcache.so' #Default for PHP 5.5 and newer

if [ "$php_version" = "5.4" ]; then
	cd /usr/local/src
	wget http://pecl.php.net/get/ZendOpcache
	tar xvfz ZendOpcache
	cd zendopcache-7.*
	phpize
	php_config_path=`which php-config`
	./configure --with-php-config=$php_config_path
	make
	make install
	rm -rf /usr/local/src/zendopcache*
	rm -f ZendOpcache
	opcache_path=`find / -name 'opcache.so'`
fi

wget -q https://raw.github.com/amnuts/opcache-gui/master/index.php -O /home/$server_name/private_html/op.php
cat > /etc/php.d/*opcache*.ini <<END
zend_extension=$opcache_path
opcache.enable=1
opcache.enable_cli=1
opcache.memory_consumption=128
opcache.interned_strings_buffer=16
opcache.max_accelerated_files=4000
opcache.max_wasted_percentage=5
opcache.use_cwd=1
opcache.validate_timestamps=1
opcache.revalidate_freq=60
opcache.fast_shutdown=1
opcache.blacklist_filename=/etc/php.d/opcache-default.blacklist
END

cat > /etc/php.d/opcache-default.blacklist <<END
/home/$server_name/public_html/wp-content/plugins/backwpup/*
/home/$server_name/public_html/wp-content/plugins/duplicator/*
/home/$server_name/public_html/wp-content/plugins/updraftplus/*
/home/$server_name/private_html/
END

systemctl restart php-fpm.service
