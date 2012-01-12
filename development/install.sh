#!/bin/bash

#************************ User Variables **************************#
hostname=''
sudoUser=''
sudoPasswd=''
rootPasswd=''
sshPort=''
#******************************************************************#

verify()
{
    var3=$3
    echo "Your $1 has been set as: $2"
    sleep 1
    echo "Is this correct? (y,n)"
    read conf
    while [[ -z "$conf" || $conf != "y" || "$conf" != "n" ]]; do 
        if [ "$conf" == "n" ]; then 
            unset ${var3} 
            break 
        elif [ "$conf" == "y" ]; then
            echo "$1 has been set as: $2"
            break
        else
            echo "Invalid option"
            sleep 1
            echo "Is this correct? (y,n)"
            read conf
        fi
    done
}

os_select()
{
    if [ "$(cat /etc/lsb-release | grep natty)" == "DISTRIB_CODENAME=natty" ];
        then
            echo "Installing Apache, PHP and MySQL for Ubuntu 11.04, Natty Narwhal..."
        else
            echo "Your (ve) Server OS is not supported in this install!"
    fi
}

set_variables()
{
    while [ -z "$hostname" ]; do
        sleep 1
        echo "Please set your Hostname: "
        read hostname
        sleep 1
        verify "Hostname" ${hostname} "hostname"
    done
    while [ -z "$sudoUser" ]; do
        sleep 1
        echo "Please set your Sudo User: "
        read sudoUser
        sleep 1
        verify "Sudo User" ${sudoUser} "sudoUser"
    done
    while [ -z "$sudoPasswd" ]; do
        sleep 1
        echo "Please set your Sudo Passwd: "
        read sudoPasswd
        sleep 1
        verify "Sudo Passwd" ${sudoPasswd} "sudoPasswd"
    done
    while [ -z "$rootPasswd" ]; do
        sleep 1
        echo "Please set your Root Passwd: "
        read rootPasswd
        sleep 1
        verify "Root Passwd" ${rootPasswd} "rootPasswd"
    done
    while [ -z "$sshPort" ]; do
        sleep 1
        echo "Please set your SSH Port: "
        read sshPort
        sleep 1
        verify "SSH Port" ${sshPort} "sshPort"
    done
}


os_select

set_variables
