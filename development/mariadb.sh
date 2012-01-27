#!/bin/bash

install_mariadb()
{
    touch ~/install.log ~/error.log
    echo -n "Building dependancies for Mariadb..."
    apt-get update >> ~/install.log
    apt-get build-dep mysql-server -y >> ~/install.log
    mkdir ~/repos && cd ~/repos
    echo "done."
    sleep 2
    echo -n "Downloading MariaDB..."
    wget -q -o ~/install.log -O http://downloads.askmonty.org/f/mariadb-5.2.10/kvm-tarbake-jaunty-x86/mariadb-5.2.10.tar.gz/from/http:/ftp.osuosl.org/pub/mariadb
    echo "done."
    mv mariadb mariadb.tar.gz && tar -zxf mariadb.tar.gz && rm -rf maria.tar.gz
    mv mariadb-* mariadb && cd mariadb
    sleep 2
    echo -n "Stage 1: Building install for MariaDB. This may take some time..."
    BUILD/compile-pentium64-max >> ~/install.log 2> ~/error.log
    echo "done."
    sleep 2
    echo -n "Stage 2: Making the install.  This may take some time..."
    make install >> ~/install.log 2> ~/error.log
    echo "done."
    sleep 2
    echo -n "Creating MySQL user..."
    groupadd mysql
    useradd -g mysql mysql
    echo "done."
    sleep 2
    echo -n "Setting MySQL Ownership and starting MariaDB..."
    scripts/mysql_install_db --user=mysql >> ~/install.log
    nohup /usr/local/mysql/bin/mysqld_safe --user=mysql >> ~/install.log
    echo "done."
}

install_mariadb
