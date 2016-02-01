#!/bin/bash

# copy this to the ubunto machine to install necessary pre-requisites
# do sudo bash ConnectPrerequisites.sh

# domain to join
DOMAIN=%1
DOMAIN_ADMIN=%2
DOMAIN_PWD=%3
RAWSaddress=%4
RemoteAgentAddress=%5
TenantInfo=%6

#    "command" : "[concat('bash install_ericom.sh ', variables('domain'),' ', variables('domainAdmin'),' ', variables('domainPwd'),' ', variables('rAWSaddress'),' ', variables('remoteAgentAddress'),' ', variables('tenantInfo'))]"
echo "DOMAIN: $DOMAIN"
echo "ADMIN:  $DOMAIN_ADMIN"
echo "PWD: $DOMAIN_PWD"
echo "RAWSaddress: $RAWSaddress"
echo "RemoteAgentAddress: $RemoteAgentAddress"
echo "TenantInfo: $TenantInfo"

# define variable of applicaiton to launch in the desktop.  can use xfce4-session or firefox for example
sudo apt-get -y update
XRDP_APP=xfce4-session

sudo apt-get -y install openssh-server

# install and editor, for example emacs
sudo apt-get -y install emacs

# install xfce window manager
sudo apt-get -y install xfce4 xfce4-goodies

# get xrdp and set the launch variable in startwm.sh
sudo apt-get -y install xrdp
sudo perl -pi.bak -E"s/^.*Xsession$/$XRDP_APP/"   /etc/xrdp/startwm.sh 

# install likewise for AD support
if [ ! -f likewise-open_6.1.0.406-0ubuntu5.1_amd64.deb ]
then

       wget http://de.archive.ubuntu.com/ubuntu/pool/main/l/likewise-open/likewise-open_6.1.0.406-0ubuntu5.1_amd64.deb
fi

if [ ! -f libglade2-0_2.6.4-2_amd64.deb ]
then
  wget http://de.archive.ubuntu.com/ubuntu/pool/main/libg/libglade2/libglade2-0_2.6.4-2_amd64.deb
fi

if [ ! -f likewise-open-gui_6.1.0.406-0ubuntu5.1_amd64.deb ]
then
  wget http://de.archive.ubuntu.com/ubuntu/pool/universe/l/likewise-open/likewise-open-gui_6.1.0.406-0ubuntu5.1_amd64.deb 
fi

sudo dpkg -i likewise-open_6.1.0.406-0ubuntu5.1_amd64.deb
sudo dpkg -i libglade2-0_2.6.4-2_amd64.deb
sudo dpkg -i likewise-open-gui_6.1.0.406-0ubuntu5.1_amd64.deb

perl -pi.bak -E's/^hosts:.*files mdns4_minimal .NOTFOUND=return. dns$/hosts: files dns [NOTFOUND=return]/'   /etc/nsswitch.conf

/etc/init.d/networking restart

# append w/o using redirection

sudo sed -i '$ a\allow-guest=false' /usr/share/lightdm/lightdm.conf.d/50-ubuntu.conf
sudo sed -i '$ a\greeter-show-manual-login=true' /usr/share/lightdm/lightdm.conf.d/50-ubuntu.conf

domainjoin-cli join $DOMAIN $DOMAIN_ADMIN $DOMAIN_PWD

ifconfig | grep -i "inet addr"

#download Ericom AccessServer and Remote Agent
if [ ! -f ericom-connect-remote-host_x64.deb ]
then
    wget http://tswc.ericom.com:501/erez/73/ericom-connect-remote-host_x64.deb
    
fi

sudo dpkg –i ericom-connect-remote-host_x64.deb

#configure the remote agent 
sudo /opt/ericom/ericom-connect-remote-agent/ericom-connect-remote-agent connect -server-url https://<$RAWSaddress>:8044 [-host-name $RemoteAgentAddress] [-tenant-info $TenantInfo]


echo REBOOT computer now with 'sudo reboot'