#!/bin/bash -e

#include function library
. myfuncs
lnmp_package=$(cd `dirname $0`;pwd)

#start the network
#network_file=/etc/sysconfig/network-scripts/ifcfg-ens33
#sed -n '/ONBOOT/c\ONBOOT=yes' $network_file
#sed -n '/BOOTPROTO/c\BOOTPROTO=dhcp' $network_file
#service network restart

yum -y update
yum -y install wget
yum -y install gcc automake autoconf libtool make
yum -y install gcc gcc-c++ glibc

#set the path of lnmp's root dir
lnmp_root_path=/alidata
Mkdir $lnmp_root_path
Mkdir $lnmp_root_path/package
Mkdir $lnmp_root_path/server
Mkdir $lnmp_root_path/webapps
Mkdir $lnmp_root_path/logs

#set the path of source package
source_path=/usr/src
Mkdir $source_path
yum -y install pcre pcre-devel
yum -y install zlib zlib-devel
yum -y install openssl openssl-devel

#============================================nginx start================================================
#create the user for nginx
user_nginx=www
group_nginx=www
groupadd -r $user_nginx
useradd -r $user_nginx -g $group_nginx

wget -P $source_path http://nginx.org/download/nginx-1.12.2.tar.gz
cd $source_path
tar -zxvf $source_path/nginx-1.12.2.tar.gz

#create direction and files for nginx
Mkdir $lnmp_root_path/logs/nginx
touch $lnmp_root_path/logs/nginx/error.log
touch $lnmp_root_path/logs/nginx/access.log
Mkdir $lnmp_root_path/logs/nginx/access
touch $lnmp_root_path/logs/nginx/access/default.log
Mkdir $lnmp_root_path/logs/nginx/error
touch $lnmp_root_path/logs/nginx/error/default.log
Mkdir $lnmp_root_path/server/nginx-1.12.2/conf/vhosts
Mkdir $lnmp_root_path/server/nginx-1.12.2/conf/proxy
Mkdir $lnmp_root_path/server/nginx-1.12.2/conf/rewrite
Mkdir $lnmp_root_path/server/nginx-1.12.2/logs

cd $source_path/nginx-1.12.2
./configure --prefix=$lnmp_root_path/server/nginx-1.12.2 --sbin-path=$lnmp_root_path/server/nginx-1.12.2/sbin/nginx --conf-path=$lnmp_root_path/server/nginx-1.12.2/nginx.conf --pid-path=$lnmp_root_path/server/nginx-1.12.2/nginx.pid --user=$user_nginx --group=$group_nginx --with-http_ssl_module --with-http_flv_module --with-http_mp4_module  --with-http_stub_status_module --with-select_module --with-poll_module --error-log-path=$lnmp_root_path/logs/nginx/error.log --http-log-path=$lnmp_root_path/logs/nginx/access.log  
#--with-pcre=$source_path/pcre-8.41 --with-zlib=$source_path/zlib-1.2.11 --with-openssl=$source_path/openssl-1.1.0b
make && make install

cd $lnmp_package
sed "s@lnmp_root_path@$(echo $lnmp_root_path)@g" nginx/nginx.conf > $lnmp_root_path/server/nginx-1.12.2/nginx.conf
cp nginx/vhosts_default.conf $lnmp_root_path/server/nginx-1.12.2/conf/vhosts/default.conf
cp nginx/rewrite_default.conf $lnmp_root_path/server/nginx-1.12.2/conf/rewrite/default.conf
cp $lnmp_root_path/server/nginx-1.12.2/html/index.html $lnmp_root_path/webapps/
echo "NGINX_HOME=$lnmp_root_path/server/nginx-1.12.2" >> /etc/profile
echo "export PATH=\$PATH:\$NGINX_HOME/sbin" >> /etc/profile
source /etc/profile
sed "s@lnmp_root_path@$(echo $lnmp_root_path)@g" nginx/init_default.conf > /etc/init.d/nginx
chmod +x /etc/init.d/nginx
service nginx start
chkconfig --add nginx
chkconfig nginx on

#============================================nginx end================================================


#============================================php start================================================

yum -y install epel-release
yum -y install libmcrypt-devel mhash-devel libxslt-devel libjpeg libjpeg-devel libpng libpng-devel freetype freetype-devel libxml2 libxml2-devel zlib zlib-devel glibc glibc-devel glib2 glib2-devel bzip2 bzip2-devel ncurses ncurses-devel curl curl-devel e2fsprogs e2fsprogs-devel krb5 krb5-devel libidn libidn-devel openssl openssl-devel

cd source_path
wget -P $source_path  http://cn2.php.net/distributions/php-7.1.11.tar.gz
tar -zxvf $source_path/php-7.1.11.tar.gz

cd $source_path/php-7.1.11
./configure --prefix=$lnmp_root_path/server/php-7.1.11 --with-config-file-path=$lnmp_root_path/server/php-7.1.11/etc --enable-fpm  --enable-mbstring --enable-pdo --with-curl --disable-debug  --disable-rpath --enable-inline-optimization --with-bz2  --with-zlib --enable-sockets --enable-sysvsem --enable-sysvshm --enable-pcntl --enable-mbregex --with-mhash --enable-zip --with-pcre-regex --with-mysqli --with-gd --with-jpeg-dir --with-freetype-dir --enable-calendar
make && make install
#--with-mcrypt 这个扩展在阿里云上能正常安装，虚拟机不行

cp $source_path/php-7.1.11/php.ini-production $lnmp_root_path/server/php-7.1.11/etc/php.ini
cp $lnmp_root_path/server/php-7.1.11/etc/php-fpm.conf.default $lnmp_root_path/server/php-7.1.11/etc/php-fpm.conf 
sed -i "/pid =/c\pid =$(echo $lnmp_root_path)/server/php-7.1.11/var/run/php-fpm.pid" $lnmp_root_path/server/php-7.1.11/etc/php-fpm.conf

cd  $lnmp_root_path/server/php-7.1.11/etc/php-fpm.d
cp www.conf.default www.conf
sed -i "/^user = nobody$/c\user = $(echo $user_nginx)" www.conf
sed -i "/^group = nobody$/c\group = $(echo $group_nginx)" www.conf
sed -i "/listen =/c\listen = 127.0.0.1:9000" www.conf
sed -i "/pm.max_children =/c\pm.max_children = 100" www.conf
sed -i "/pm.start_servers =/c\pm.start_servers = 20" www.conf
sed -i "/pm.min_spare_servers =/c\pm.min_spare_servers = 5" www.conf
sed -i "/pm.max_spare_servers =/c\pm.max_spare_servers = 35" www.conf

echo "PHP_HOME=$lnmp_root_path/server/php-7.1.11" >> /etc/profile
echo "export PATH=\$PATH:\$PHP_HOME/bin:\$PHP_HOME/sbin" >> /etc/profile
source /etc/profile

cd $lnmp_package
sed "s@lnmp_root_path@$(echo $lnmp_root_path)@" php/init_default.conf > /etc/init.d/php-fpm
chmod +x /etc/init.d/php-fpm
service php-fpm start
chkconfig --add php-fpm
chkconfig php-fpm on

#=============================================php end===========================================================================

#=============================================mysql start=======================================================================

yum -y install libaio*

#set user for mysql
user_mysql=mysql
group_mysql=mysql
groupadd -r $group_mysql
useradd -r $user_mysql -g $group_mysql

cd $source_path
wget https://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-5.7.20-linux-glibc2.12-x86_64.tar.gz
tar -zxvf mysql-5.7.20-linux-glibc2.12-x86_64.tar.gz
mv mysql-5.7.20-linux-glibc2.12-x86_64 $lnmp_root_path/server/mysql-5.7.20/

cd $lnmp_package
sed "s@lnmp_root_path@$(echo $lnmp_root_path)@" mysql/default_my.cnf > /etc/my.cnf

Mkdir $lnmp_root_path/server/mysql-5.7.20/data
Mkdir $lnmp_root_path/server/mysql-5.7.20/tmp
Mkdir $lnmp_root_path/logs/mysql
Mkdir $lnmp_root_path/logs/mariadb
touch $lnmp_root_path/logs/mysql/error.log
touch $lnmp_root_path/logs/mysql/mysql.pid
chown -R mysql.mysql $lnmp_root_path/logs/mysql
touch $lnmp_root_path/logs/mariadb/error.log
touch $lnmp_root_path/logs/mariadb/mariadb.pid
chown -R mysql.mysql $lnmp_root_path/logs/mariadb
chown -R mysql.mysql $lnmp_root_path/server/mysql-5.7.20/

cp -a /alidata/server/mysql-5.7.20/support-files/mysql.server /etc/init.d/mysqld
sed -i "/^basedir=$/c\basedir=$(echo $lnmp_root_path)/server/mysql-5.7.20" /etc/init.d/mysqld
sed -i "/^datadir=$/c\datadir=$(echo $lnmp_root_path)/server/mysql-5.7.20/data" /etc/init.d/mysqld

cd $lnmp_root_path/server/mysql-5.7.20/bin/
./mysqld --initialize --user=$user_mysql --basedir=$lnmp_root_path/server/mysql-5.7.20/ --datadir=$lnmp_root_path/server/mysql-5.7.20/data/
service mysqld start
chkconfig --add mysqld
chkconfig mysqld on
mysql_password=$(awk '/root@localhost:/{print $NF}' $lnmp_root_path/logs/mysql/error.log)
echo "$mysql_password" > $lnmp_package/mysql/temp_password
#这里会记录密码 暂时不会用shell修改数据库内容 修改密码和远程登录权限需要手动去做
# 下面两行是修改数据库密码和开启远程通过root账号访问权限，登录mysql后手动开启
# set password = password('your password')
# grant all privileges on *.* to root@'%' identified by 'your password' with grant option;
# flush privileges;
#关闭firewalld防火墙，开启iptables防火墙并开放80,3306端口
systemctl stop firewalld.service
systemctl disable firewalld.service
systemctl mask firewalld.service
yum -y install iptables-services
sed -i '/--dport 22/a\-A INPUT -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT' /etc/sysconfig/iptables
sed -i '/--dport 22/a\-A INPUT -m state --state NEW -m tcp -p tcp --dport 3306 -j ACCEPT' /etc/sysconfig/iptables
systemctl enable iptables
systemctl start iptables

#===============================================mysql end======================================================================

#===============================================php  pdo_mysql扩展======================================================================
service php-fpm stop
cd $source_path/php-7.1.11/ext/pdo_mysql
$lnmp_root_path/server/php-7.1.11/bin/phpize
./configure --with-php-config=$lnmp_root_path/server/php-7.1.11/bin/php-config --with-pdo-mysql=$lnmp_root_path/server/mysql-5.7.20/
make
make install > $lnmp_package/php/extension_pdo_path
$extension_pdo_path=$(cat $lnmp_package/php/extension_pdo_path)
sed -i "s@;extension=php_pdo_mysql@extension=$(echo $extension_pdo_path)pdo_mysql.so@" $lnmp_root_path/server/php-7.1.11/etc/php.ini
service php-fpm start




