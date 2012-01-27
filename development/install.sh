#!/bin/bash

#************************ User Variables **************************#
hostname=''
sudoUser=''
sudoPasswd=''
rootPasswd=''
sshPort=''
disRoot=''
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
            touch log/install.log
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
    cp files/iptables.up.rules tmp/fw.$$
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

    `

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
    sleep .5
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

set_locale

set_timezone
