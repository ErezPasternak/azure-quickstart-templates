#!/bin/bash

# copy this to the ubunto machine to install necessary pre-requisites

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
time sudo apt-get -y update
XRDP_APP=xfce4-session

time sudo apt-get -y install openssh-server

# install firefix, 
sudo apt-get -y install firefox

# install chrome,
time wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
time sudo dpkg -i google-chrome-stable_current_amd64.deb
time sudo apt-get -y --force-yes install -f

# install xfce window manager
time sudo apt-get -y install xfce4 xfce4-goodies

# get xrdp and set the launch variable in startwm.sh
time sudo apt-get -y install xrdp
time sudo perl -pi.bak -E"s/^.*Xsession$/$XRDP_APP/"   /etc/xrdp/startwm.sh 

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

time sudo dpkg -i likewise-open_6.1.0.406-0ubuntu5.1_amd64.deb
time sudo dpkg -i libglade2-0_2.6.4-2_amd64.deb
time sudo dpkg -i likewise-open-gui_6.1.0.406-0ubuntu5.1_amd64.deb

# install QT
time sudo apt-get install qt5-default

#install unzip 
time apt-get install unzip

perl -pi.bak -E's/^hosts:.*files mdns4_minimal .NOTFOUND=return. dns$/hosts: files dns [NOTFOUND=return]/'   /etc/nsswitch.conf

/etc/init.d/networking restart

# append w/o using redirection

time sudo sed -i '$ a\allow-guest=false' /usr/share/lightdm/lightdm.conf.d/50-ubuntu.conf
time sudo sed -i '$ a\greeter-show-manual-login=true' /usr/share/lightdm/lightdm.conf.d/50-ubuntu.conf

domainjoin-cli join $DOMAIN $DOMAIN_ADMIN $DOMAIN_PWD

ifconfig | grep -i "inet addr"

#download Ericom AccessServer and Remote Agent
if [ ! -f ericom-connect-remote-host_x64.deb.zip ]
then
    wget http://tswc.ericom.com:501/erez/73/ericom-connect-remote-host_x64.deb.zip
    
fi

time unzip ericom-connect-remote-host_x64.deb.zip
time sudo dpkg –i ericom-connect-remote-host_x64.deb

#configure the remote agent 
time sudo /opt/ericom/ericom-connect-remote-agent/ericom-connect-remote-agent connect -server-url https://<$RAWSaddress>:8044 [-host-name $RemoteAgentAddress] [-tenant-info $TenantInfo]


echo REBOOT computer now with 'sudo reboot'