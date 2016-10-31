#!/bin/bash

if [ $# -eq 0 ]
  then
    echo "Usage: " $0 "[Domain] [DomainAdmin] [DomainAdminPasswd] [RAWS-IP] [TenantInfo] [RemoteAgentAddress] [StartupApp]"
    exit
fi

# domain to join
DOMAIN=$1
DOMAIN_ADMIN=$2
DOMAIN_PWD=$3
RAWSaddress=$4
TenantInfo=$5
RemoteAgentAddress=$6
StartupApp=$7

RemoteAgentPackageFTP=https://download.ericom.com/public/file/v1MenAP95UuK70L0emqpCQ/ericom-connect-remote-host_x64.deb
xrdpPackageFTP=https://download.ericom.com/public/file/69mOgYm04EOZjGfU4AVDnA/ericom-xrdp.deb
x11rdpPackageFTP=https://download.ericom.com/public/file/NDTFEzvKyECVU2e33g_Ylw/x11rdp_0.9.0%2Bericom%2B32-32_amd64.deb
RemoteAgentPackage=ericom-connect-remote-host_x64.deb
xrdpPackage=ericom-xrdp.deb
x11rdpPackage=x11rdp_0.9.0+ericom+32-32_amd64

# Update System #BH
time sudo apt-get -y update

# install QT
time sudo apt-get -y install qt5-default

# install xfce window manager
time sudo apt-get -y install xfce4 xfce4-goodies

echo xfce4-session >~/.xsession

#install new dependencies (for Printing)
time sudo apt-get install cups
time sudo apt-get install cups-filters
time sudo apt-get install cups-daemon
time sudo apt-get install socat

# install x11rdp
if [ ! -f x11rdpPackage ]
then
   wget  --no-check-certificate $x11rdpPackageFTP
   time sudo dpkg -i $x11rdpPackage
fi

# get xrdp and set the launch variable in startwm.sh
#time sudo apt-get -y install xrdp
if [ ! -f xrdpPackageFTP ]
then
    wget  --no-check-certificate $xrdpPackageFTP
    time sudo dpkg -i $xrdpPackage
fi

if [ ! -f RemoteAgentPackage ]
then
    wget  --no-check-certificate $RemoteAgentPackageFTP
    time sudo dpkg -i $RemoteAgentPackage
fi
time sudo service xrdp restart

# we will install the app and set to be un startup
# install app
if [ $StartupApp -neq "" ]
   then
     time sudo apt-get -y install $StartupApp
     # define variable of applicaiton to launch in the desktop.  can use xfce4-session or firefox for example
     XRDP_APP=$StartupApp
     time sudo perl -pi.bak -E"s/^.*Xsession$/$XRDP_APP/"   /etc/xrdp/startwm.sh 
fi

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

# append w/o using redirection

time sudo sed -i '$ a\allow-guest=false' /usr/share/lightdm/lightdm.conf.d/50-ubuntu.conf
time sudo sed -i '$ a\greeter-show-manual-login=true' /usr/share/lightdm/lightdm.conf.d/50-ubuntu.conf

# adding this machine into the domain
time sudo domainjoin-cli join $DOMAIN $DOMAIN_ADMIN $DOMAIN_PWD

# register this machine in the DNS (secure)
time sudo lw-update-dns

#download Ericom AccessServer and Remote Agent
if [ ! -f ericom-connect-remote-host_x64.deb.zip ]
then
    wget http://tswc.ericom.com:501/erez/751/ericom-connect-remote-host_x64.deb.zip    
fi

time sudo unzip ericom-connect-remote-host_x64.deb.zip
time sudo su 

#install Ericom Connect RemoteAgent an AccessServer
time dpkg -i ericom-connect-remote-host_x64.deb

#configure the remote agent 
time sudo /opt/ericom/ericom-connect-remote-agent/ericom-connect-remote-agent connect -server-url https://$RAWSaddress:8044 
# -host-name $RemoteAgentAddress -tenant-info $TenantInfo

echo "Machine was configured successfully - Please REBOOT ypour system then your machine will be Ready for usage"

