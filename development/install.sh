#!/bin/bash

#************************ User Variables **************************#
hostname=''
sudoUser=''
sudoUserPasswd=''
rootPasswd=''
sshPort=''
#******************************************************************#

verify()
{
    echo "Your $1 has been set as: $2"
    sleep 1
    echo "Is this correct? (y,n)"
    read conf
    while [[ -z "$conf" || $conf != "y" || "$conf" != "n" ]]; do 
        if [ "$conf" == "n" ]; then 
            ${2}='' 
            break 
        elif [ "$conf" == "y" ]; then
            echo "Hostname has been set as: $2"
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
            sleep 1
        else
            echo "Your (ve) Server OS is not supported in this install!"
            sleep 1
    fi
}

set_variables()
{
    while [ -z "$hostname" ]; do
        echo "Please set your Hostname: "
        read hostname
        sleep 1
        verify "Hostname" ${hostname}
    done
    echo "$hostname is....."
    while [ -z "$sudoUser" ]; do
        echo "Please set your Sudo User: "
        read sudoUser
        sleep 1
    done

}


os_select

set_variables
