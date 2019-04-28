#startup script for the php-fpm 
# php-fpm version:7.1.11
# chkconfig: - 85 15
# description: php-fpm
# processname: php-fpm
# pidfile: lnmp_root_path/server/php-7.1.11/var/run/php-fpm.pid
# config: lnmp_root_path/server/php-7.1.11/etc/php-fpm.conf

php_command=lnmp_root_path/server/php-7.1.11/sbin/php-fom
php_config=lnmp_root_path/server/php-7.1.11/etc/php-fpm.conf
php_pid=lnmp_root_path/server/php-7.1.11/var/run/php-fpm.pid
RETVAL=0
prog="php-fpm"

#start function
php_fpm_start() {
    lnmp_root_path/server/php-7.1.11/sbin/php-fpm
}

start(){
    if [ -e $php_pid  ]
    then
    echo "php-fpm already start..."
    exit 1
    fi
    php_fpm_start
}

stop(){
    if [ -e $php_pid ]
    then
    parent_pid=`cat $php_pid`
    all_pid=`ps -ef | grep php-fpm | awk '{if('$parent_pid' == $3){print $2}}'`
    for pid in $all_pid
    do
            kill $pid
        done
        kill $parent_pid
    fi
    exit 1
}

restart(){
    stop
    start
}

# See how we were called.
case "$1" in
start)
        start
        ;;
stop)
        stop
        ;;
restart)
        stop
        start
        ;;
status)
        status $prog
        RETVAL=$?
        ;;
*)
        echo $"Usage: $prog {start|stop|restart|status}"
        exit 1
esac
exit $RETVAL
