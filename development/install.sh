#!/bin/bash

#************************ User Variables **************************#
hostname='ohaiworld.com'
sudoUser='rawr'
sudoPasswd='bar'
rootPasswd='foo'
dbPasswd='baz'
sshPort='22'
disRoot=''
dbType=''
wpDB=''
wpUser=''
wpPasswd=''
locale='en_US.UTF-8'
timeZone='America/Los_Angeles'
#******************************************************************#

verify()
{
    var3=$3
    echo "Your $1 has been set as: $2"
    sleep .5
    echo "Is this correct? (y,n)"
    read conf
    while [[ -z "$conf" || "$conf" != "y" || "$conf" != "n" ]]; do 
        if [ "$conf" == "n" ]; then 
            unset ${var3} 
            break 
        elif [ "$conf" == "y" ]; then
            echo "$1 has been confirmed."
            break
        else
            echo "Invalid option"
            sleep .5
            echo "Please select one option: (y,n)"
            read conf
        fi
    done
}

clear_tmp()
{
    rm -rf tmp/*.$$
}

set_hostname()
{
    touch TEST
    echo -n "Applying Hostname: ${hostname} to config..."
    hostname ${hostname}
    echo ${hostname} > TEST
    echo "127.0.0.1 ${hostname}" >> TEST
    echo "done."
}

create_sudo_user()
{
    echo -n "Creating a new sudo user: ${sudoUser}"
    useradd -d /home/${sudoUser} -s /bin/bash -m ${sudoUser}
    echo "${sudoUser}:${sudoPasswd}" | chpasswd
    echo "${sudoUser} ALL=(ALL) ALL" >> /etc/sudoers
    {
        echo 'export PS1="\[\e[32;1m\]\u\[\e[0m\]\[\e[32m\]@\h\[\e[36m\]\w \[\e[33m\]\$ \[\e[0m\]"'
    } >> /home/$sudo_user/.bashrc
    echo "done."
}

set_root_passwd()
{
    echo -n "Applying root password to config..."
    echo "${rootPasswd}\n${rootPasswd}" > tmp/pass.$$
    passwd root < tmp/pass.$$ > /dev/null 2>&1
    echo "done."
    clear_tmp
}

os_select()
{
    if [ "$(cat /etc/lsb-release | grep natty)" == "DISTRIB_CODENAME=natty" ];
        then
            echo "Installing Apache, PHP and MySQL for Ubuntu 11.04, Natty Narwhal..."
            touch ~/install.log
        else
            echo "Your (ve) Server OS is not supported in this install!"
    fi
}

ssh_config()
{
    ssh='/etc/ssh/sshd_config'
    echo "Configuring SSH..."
    mkdir ~/.ssh && chmod 700 ~/.ssh/
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.`date "+%Y-%m-%d"`
    sed -i -r 's/\s*X11Forwarding\s+yes/X11Forwarding no/g' ${ssh}
    sed -i -r 's/\s*UsePAM\s+yes/UsePAM no/g' ${ssh}
    sed -i -r 's/\s*UseDNS\s+yes/UseDNS no/g' ${ssh}
    perl -p -i -e 's|LogLevel INFO|LogLevel VERBOSE|g;' ${ssh}
    grep -q "UsePAM no" ${ssh} || echo "UsePAM no" >> ${ssh}
    grep -q "UseDNS no" ${ssh} || echo "UseDNS" >> ${ssh}
    sleep 2
    echo -n "Applying SSH port..."
    sed -i -r "s/\s*Port\s+[0-9]+/Port ${sshPort}/g" ${ssh}
    cp conf/iptables.up.rules tmp/fw.$$
    sed -i -r "s/\s+22\s+/ ${sshPort} /" tmp/fw.$$
    echo "done."
    sleep .5
    echo -n "Disabling root access..."
    sed -i -r 's/\s*PermitRootLogin\s+yes/PermitRootLogin no/g' ${ssh}
    echo "AllowUsers ${sudoUser}" >> ${ssh}
    echo "done."
}

firewall_config()
{
    echo -n "Configuring firewall..."
    cp tmp/fw.$$ /etc/iptables.up.rules
    iptables -F
    iptables-restore < /etc/iptables.up.rules > /dev/null 2>&1 &&
    sed -i 's%pre-up iptables-restore < /etc/iptables.up.rules%%g' /etc/network/interfaces
    sed -i -r 's%\s*iface\s+lo\s+inet\s+loopback%iface lo inet loopback\npre-up iptables-restore < /etc/iptables.up.rules%g' /etc/network/interfaces
    /etc/init.d/ssh reload > /dev/null 2>&1
    echo "done."
}

tmp_config()
{
    echo "Configuring temporary directory..."
    echo "APT::ExtractTemplates::TempDir \"/var/local/tmp\";" > /etc/apt/apt.conf.d/50extracttemplates && mkdir /var/local/tmp
    mkdir ~/tmp && chmod 777 ~/tmp
    mount --bind ~/tmp /tmp
    echo "done."
}

install_base()
{
    echo -n "Setting up base packages..."
    apt-get update >> ~/install.log
    apt-get -y safe-upgrade >> ~/install.log
    apt-get -y full-upgrade >> ~/install.log
    apt-get -y install curl build-essentials python-software-properties git-core htop >> ~/install.log
    echo "done.."
}

install_php()
{

    echo -n "Installing PHP..."
    mkdir -p /var/www
    apt-get -y install php5-cli php5-common php5-mysql php5-suhosin php5-gd php5-curl >> ~/install.log
    apt-get -y install php5-fpm php5-cgi php5-pear php-apc php5-dev libpcre3-dev >> ~/install.log
    perl -p -i -e 's|# Default-Stop:|# Default-Stop:      0 1 6|g;' /etc/init.d/php5-fpm
    cp /etc/php5/fpm/pool.d/www.conf /etc/php5/fpm/pool.d/www.conf.`date "+%Y-%m-%d"`
    chmod 000 /etc/php5/fpm/pool.d/www.conf.`date "+%Y-%m-%d"` && mv /etc/php5/fpm/pool.d/www.conf.`date "+%Y-%m-%d"` /tmp
    perl -p -i -e 's|listen = 127.0.01:9000|listen = /var/run/php5-fpm.sock|g;' /etc/php5/fpm/pool.d/www.conf
    perl -p -i -e 's|;listen.allowed_clients = 127.0.0.1|listen.allowed_clients = 127.0.0.1|g;' /etc/php5/fpm/pool.d/www.conf
    perl -p -i -e 's|;pm.status_path = /status|pm.status_path = /status|g;' /etc/php5/fpm/pool.d/www.conf
    perl -p -i -e 's|;ping.path = /ping|ping.path = /ping|g;' /etc/php5/fpm/pool.d/www.conf
    perl -p -i -e 's|;ping.response = pong|ping.response = pong|g;' /etc/php5/fpm/pool.d/www.conf
    perl -p -i -e 's|;request_terminate_timeout = 0|request_terminate_timeout = 300s|g;' /etc/php5/fpm/pool.d/www.conf
    perl -p -i -e 's|;request_slowlog_timeout = 0|request_slowlog_timeout = 5s|g;' /etc/php5/fpm/pool.d/www.conf
    perl -p -i -e 's|;listen.backlog = -1|listen.backlog = -1|g;' /etc/php5/fpm/pool.d/www.conf
    sed -i -r "s/www-data/$sudo_user/g" /etc/php5/fpm/pool.d/www.conf
    perl -p -i -e 's|;slowlog = log/\$pool.log.slow|slowlog = /var/log/php5-fpm.log.slow|g;' /etc/php5/fpm/pool.d/www.conf
    perl -p -i -e 's|;catch_workers_output = yes|catch_workers_output = yes|g;' /etc/php5/fpm/pool.d/www.conf
    perl -p -i -e 's|pm.max_children = 50|pm.max_children = 25|g;' /etc/php5/fpm/pool.d/www.conf
    perl -p -i -e 's|;pm.start_servers = 20|pm.start_servers = 3|g;' /etc/php5/fpm/pool.d/www.conf
    perl -p -i -e 's|pm.min_spare_servers = 5|pm.min_spare_servers = 2|g;' /etc/php5/fpm/pool.d/www.conf
    perl -p -i -e 's|pm.max_spare_servers = 35|pm.max_spare_servers = 4|g;' /etc/php5/fpm/pool.d/www.conf
    perl -p -i -e 's|;pm.max_requests = 500|pm.max_requests = 500|g;' /etc/php5/fpm/pool.d/www.conf
    perl -p -i -e 's|;emergency_restart_threshold = 0|emergency_restart_threshold = 10|g;' /etc/php5/fpm/main.conf
    perl -p -i -e 's|;emergency_restart_interval = 0|emergency_restart_interval = 1m|g;' /etc/php5/fpm/main.conf
    perl -p -i -e 's|;process_control_timeout = 0|process_control_timeout = 5s|g;' /etc/php5/fpm/main.conf
    perl -p -i -e 's|;daemonize = yes|daemonize = yes|g;' /etc/php5/fpm/main.conf
    cp /etc/php5/fpm/php.ini /etc/php5/fpm/php.ini.`date "+%Y-%m-%d"`
    perl -p -i -e 's|;date.timezone =|date.timezone = America/Los_Angeles|g;' /etc/php5/fpm/php.ini
    perl -p -i -e 's|expose_php = On|expose_php = Off|g;' /etc/php5/fpm/php.ini
    perl -p -i -e 's|allow_url_fopen = On|allow_url_fopen = Off|g;' /etc/php5/fpm/php.ini
    perl -p -i -e 's|;cgi.fix_pathinfo=1|cgi.fix_pathinfo=0|g;' /etc/php5/fpm/php.ini
    perl -p -i -e 's|;realpath_cache_size = 16k|realpath_cache_size = 128k|g;' /etc/php5/fpm/php.ini
    perl -p -i -e 's|;realpath_cache_ttl = 120|realpath_cache_ttl = 600|g;' /etc/php5/fpm/php.ini
    perl -p -i -e 's|disable_functions =|disable_functions = "system,exec,shell_exec,passthru,escapeshellcmd,popen,pcntl_exec"|g;' /etc/php5/fpm/php.ini
    cp conf/apc.ini /etc/php5/fpm/conf.d/apc.ini
    service php5-fpm stop > /dev/null 2>&1
    service php5-fpm start > /dev/null 2>&1
    echo "done."
}

install_database()
{
    if [ ${dbType} == "MariaDB" ];
        then
            echo -n "Installing MariaDB..."
            apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 1BB943DB
            touch /etc/apt/sources.list.d/mariadb.list
            echo "deb http://mirrors.xmission.com/mariadb/repo/5.2/ubuntu maverick main
deb-src http://mirrors.xmission.com/mariadb/repo/5.2/ubuntu maverick main" > /etc/apt/sources.list.d/mariadb.list
            apt-get update
            echo "mariadb-server mariadb-server/root_password select $dbPasswd" | debconf-set-selections
            echo "mariadb-server mariadb-server/root_password_again select $dbPasswd" | debconf-set-selections
            apt-get install mariadb-server mariadb-client >> ~/install.log
    elif [ ${dbType} == "MySQL" ];
        then
            echo -n "Installing MySQL..."
            echo "mysql-server mysql-server/root_password select $dbPasswd" | debconf-set-selections
            echo "mysql-server mysql-server/root_password_again select $dbPasswd" | debconf-set-selections
            apt-get install -y mysql-server >> ~/install.log
    else
        echo "Invalid database type"
        unset ${dbType}
    fi
    cat <<EOF > /root/.my.cnf
[client]
user=root
password=$mysqlPasswd

EOF
    chmod 600 /root/.my.cnf
    mv /etc/mysql/my.cnf /etc/mysql/my.cnf.`date "+%Y-%m-%d"`
    ./conf/my.sh
    touch /var/log/mysql/mysql/mysql-slow.log
    chown mysql:mysql /var/log/mysql/mysql-slow.log
    service mysqld restart > /dev/null 2>&1
    echo "done."
}

config_wp_database()
{
    echo -n "Creating WordPress database..."
    mysql -e "CREATE DATABASE ${wpDB}"
    mysql -e "GRANT ALL PRIVILEGES ON ${wpDB}.* to ${wpUser}@localhost INDENTIFIED BY '${wpPasswd}'"
    mysql -e "FLUSH PRIVILEGES"
    echo "done."
}

install_nginx()
{
    echo -n "Installing Nginx..."
    add-apt-respository ppa:nginx/stable > /dev/null 2>&1
    apt-get -y update >> ~/install.log
    apt-get -y install nginx >> ~/install.log
    cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.`date "+%Y-%m-%d"`
    rm -rf /etc/nginx/nginx.conf
    cp conf/nginx.conf /etc/nginx/nginx.conf
    /bin/mkdir -p ~/.vim/syntax
    cp conf/nginx.conf ~/.vim/syntax/nginx.vim
    touch ~/.vim/filetype.vim
    echo "au BufRead,BufNewFile /etc/nginx/* set ft=nginx" >> ~/.vim/filetype.vim
    rm -rf /etc/nginx/sites-available/default
    unlink /etc/nginx/sites-enabled/default
    cp conf/mydomain.com /etc/nginx/sites-available/${hostname}.conf
    rm -rf /etc/nginx/fastcgi_params
    cp conf/fastcgi_params /etc/nginx/fastcgi_params
    sed -i -r "s/sudoer/${sudoUser}/g" /etc/nginx/nginx.conf
    sed -i -r "s/mydomain.com/${$hostname}/g" /etc/nginx/sites-available/${hostname}.conf
    sed -i -r "s/sudoer/${sudoUser}/g" /etc/nginx/sites-available/${hostname}.conf
    ln -s -v /etc/nginx/sites-available/${hostname}.conf /etc/nginx/sites-enabled/001-$hostname.conf > /dev/null 2>&1
    rm -rf /var/www/nginx-default
    service nginx restart >/dev/null 2>&1
    echo -n "Done."
}

install_postfix()
{
    echo -n "Installing Postfix..."
    echo "postfix postifx/mailname string ${hostname}" | debconf-set-selections
    echo "postfix postfix/main_mailer_type select Internet Site" | debconf-set-selections
    apt-get -y install postfix >> ~/install.log
    /usr/sbin/postconf -e "inet_interfaces = loopback-only"
    service postfix restart > /dev/null 2>&1
    echo "done."
}

set_variables()
{
    while [ -z "$hostname" ]; do
        sleep .5
        echo "Please set your Hostname: "
        read hostname
        sleep .5
        verify "Hostname" ${hostname} "hostname"
    done
    #set_hostname
    while [ -z "$sudoUser" ]; do
        sleep .5
        echo "Please set your Sudo User: "
        read sudoUser
        if id ${sudoUser} > /dev/null 2>&1; then
            echo "Sudo User: ${sudoUser} already exists.  Please select a new Sudo User."
            unset sudoUser
        else
            sleep .5
            verify "Sudo User" ${sudoUser} "sudoUser"
        fi
    done
    while [ -z "$sudoPasswd" ]; do
        sleep .5
        echo "Please set your Sudo Passwd: "
        read sudoPasswd
        sleep .5
        verify "Sudo Passwd" ${sudoPasswd} "sudoPasswd"
    done
    #create_sudo_user
    while [ -z "$rootPasswd" ]; do
        sleep .5
        echo "Please set your Root Passwd: "
        read rootPasswd
        sleep .5
        verify "Root Passwd" ${rootPasswd} "rootPasswd"
    done
    #set_root_passwd
    while [ -z "$sshPort" ]; do
        sleep .5
        echo "Please set your SSH Port: "
        read sshPort
        sleep .5
        verify "SSH Port" ${sshPort} "sshPort"
    done
    while [ -z "$disRoot" ]; do
        sleep .5
        echo "Would you like to disable root access? (y,n)"
        read disRoot
        sleep .5
        if [ "$disRoot" == "n" ]; then
            unset ${disRoot}
        fi
        sleep .5
        verify "Disable Root" ${disRoot} "disRoot"
    done
    while [ -z "$choice" ]; do
        sleep .5
        echo "Choose a database..."
        echo "0) MariaDB"
        echo "1) MySQL"
        read choice
        sleep .5
        case "$choice" in
            0) echo "MariaDB has been selected"
                dbType="MariaDB"
                ;;
            1) echo "MySQL has been selected"
                dbType="MySQL"
                ;;
        esac
        sleep .5
        verify "Database" ${dbType} "dbType"
    done
    echo "Settings done."
}

set_locale()
{

    echo -n "Setting up system locale to $locale..."
    { 
        locale-gen $locale
        unset LANG
        /usr/sbin/update-locale LANG=$locale
    } > /dev/null 2>&1
    export LANG=$locale
    sleep .5
    echo "done."

}

set_timezone()
{
    
    echo -n "Setting Timezone to $timeZone..."
    echo "$timezone" > /etc/timezone
    dpkg-reconfigure -f noninteractive tzdata > /dev/null 2>&1
    echo "done."
}

os_select

set_variables

#set_locale

#set_timezone

#set_hostname

#create_sudo_user

#set_root_passwd

#ssh_config

#firewall_config

#tmp_config

#install_base

#install_php

#install_database

#config_wp_database

#install_nginx

#install_postfix
