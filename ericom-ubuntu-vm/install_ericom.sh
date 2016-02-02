#!/bin/bash

time sudo apt-get -y update

# domain to join
DOMAIN=%1
DOMAIN_ADMIN=%2
DOMAIN_PWD=%3
RAWSaddress=%4
TenantInfo=%5
RemoteAgentAddress=%6

#    "command" : "[concat('bash install_ericom.sh ', variables('domain'),' ', variables('domainAdmin'),' ', variables('domainPwd'),' ', variables('rAWSaddress'),' ', variables('remoteAgentAddress'),' ', variables('tenantInfo'))]"
echo "DOMAIN: $DOMAIN"
echo "ADMIN:  $DOMAIN_ADMIN"
echo "PWD: $DOMAIN_PWD"
echo "RAWSaddress: $RAWSaddress"
echo "RemoteAgentAddress: $RemoteAgentAddress"
echo "TenantInfo: $TenantInfo"

time sudo apt-get -y install language-pack-UTF-8

# define variable of applicaiton to launch in the desktop.  can use xfce4-session or firefox for example
XRDP_APP=xfce4-session

# install QT
time sudo apt-get -y install qt5-default

# install Openssh server
time sudo apt-get -y install openssh-server

# install firefix, 
time sudo apt-get -y install firefox

# install chrome,
# time wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
# time sudo dpkg -i google-chrome-stable_current_amd64.deb
# time sudo apt-get -y --force-yes install -f

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

# might help the likewise 
time sudo apt-get -f install 

time sudo dpkg -i likewise-open_6.1.0.406-0ubuntu5.1_amd64.deb
time sudo dpkg -i libglade2-0_2.6.4-2_amd64.deb
time sudo dpkg -i likewise-open-gui_6.1.0.406-0ubuntu5.1_amd64.deb

#install unzip 
time sudo apt-get -y install unzip

time sudo perl -pi.bak -E's/^hosts:.*files mdns4_minimal .NOTFOUND=return. dns$/hosts: files dns [NOTFOUND=return]/'   /etc/nsswitch.conf

/etc/init.d/networking restart

# append w/o using redirection

time sudo sed -i '$ a\allow-guest=false' /usr/share/lightdm/lightdm.conf.d/50-ubuntu.conf
time sudo sed -i '$ a\greeter-show-manual-login=true' /usr/share/lightdm/lightdm.conf.d/50-ubuntu.conf

time sudo domainjoin-cli join $DOMAIN $DOMAIN_ADMIN $DOMAIN_PWD

time sudo ifconfig | grep -i "inet addr"

#download Ericom AccessServer and Remote Agent
if [ ! -f ericom-connect-remote-host_x64.deb.zip ]
then
    wget http://tswc.ericom.com:501/erez/75/ericom-connect-remote-host_x64.deb.zip    
fi

time sudo unzip ericom-connect-remote-host_x64.deb.zip
time sudo su 
time dpkg -i ericom-connect-remote-host_x64.deb

#configure the remote agent 
time sudo /opt/ericom/ericom-connect-remote-agent/ericom-connect-remote-agent connect -server-url https://$RAWSaddress:8044 -host-name $RemoteAgentAddress -tenant-info $TenantInfo

echo REBOOT computer now with 'sudo reboot'