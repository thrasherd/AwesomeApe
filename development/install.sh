#!/bin/bash

#************************ User Variables **************************#
hostname=''
sudoUser=''
sudoPasswd=''
rootPasswd=''
sshPort=''
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
    while [[ -z "$conf" || $conf != "y" || "$conf" != "n" ]]; do 
        if [ "$conf" == "n" ]; then 
            unset ${var3} 
            break 
        elif [ "$conf" == "y" ]; then
            echo "$1 has been confirmed."
            break
        else
            echo "Invalid option"
            sleep .5
            echo "Is this correct? (y,n)"
            read conf
        fi
    done
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

os_select()
{
    if [ "$(cat /etc/lsb-release | grep natty)" == "DISTRIB_CODENAME=natty" ];
        then
            echo "Installing Apache, PHP and MySQL for Ubuntu 11.04, Natty Narwhal..."
            touch install.log
        else
            echo "Your (ve) Server OS is not supported in this install!"
    fi
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
    set_hostname
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
    while [ -z "$rootPasswd" ]; do
        sleep .5
        echo "Please set your Root Passwd: "
        read rootPasswd
        sleep .5
        verify "Root Passwd" ${rootPasswd} "rootPasswd"
    done
    while [ -z "$sshPort" ]; do
        sleep .5
        echo "Please set your SSH Port: "
        read sshPort
        sleep .5
        verify "SSH Port" ${sshPort} "sshPort"
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
    
    echo "Setting Timezone to $timeZone..."
    echo "$timezone" > /etc/timezone
    dpkg-reconfigure -f noninteractive tzdata > /dev/null 2>&1
    echo "done."
}

os_select

set_variables

set_locale

set_timezone
