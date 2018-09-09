mysqlhost="localhost"
mysqldb="youtube"
mysqluser="facebook"
mysqlpass="google"

wget https://wordpress.org/latest.tar.gz
tar zxf latest.tar.gz
mv wordpress/* ./
rm -f index.html

wget -O /tmp/wp.keys https://api.wordpress.org/secret-key/1.1/salt/

sed -e "s/localhost/"$mysqlhost"/" -e "s/database_name_here/"$mysqldb"/" -e "s/username_here/"$mysqluser"/" -e "s/password_here/"$mysqlpass"/" wp-config-sample.php > wp-config.php
sed -i '/#@-/r /tmp/wp.keys' wp-config.ph
sed -i "/#@+/,/#@-/d" wp-config.php

rmdir wordpress
rm latest.tar.gz
rm /tmp/wp.keys
rm wp

chown -R nginx:nginx *
