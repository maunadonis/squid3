#!/bin/bash
cp /usr/share/zoneinfo/Asia/Manila /etc/localtime

apt install -y dos2unix debconf-utils pwgen mlocate dh-make

MYIP=$(wget -qO- icanhazip.com);
genNS=$(echo "$(pwgen 5 1)" | tr '[:upper:]' '[:lower:]')
secretkey='server'
dnsresolverName="1.1.1.1"
dnsresolverType="udp"
dnsresolver="1.1.1.1:53"

dnsdomain=amaun.xyz
dnszone=9f9fc8fdf85dcabaf09e2fc144a25a2e

arecord=$(cat /root/domain)
nsrecord="$genNS.$dnsdomain"
hostname=$arecord
domain=$nsrecord

sudo apt-get autoremove --purge squid -y

# install squid
cd
serverDistro=`awk '/^ID=/' /etc/*-release | awk -F'=' '{ print tolower($2) }'`
if [[ $serverDistro == "ubuntu" ]]
then
    sudo cp /etc/apt/sources.list /etc/apt/sources.list_backup
    echo "deb http://us.archive.ubuntu.com/ubuntu/ trusty main universe" | sudo tee --append /etc/apt/sources.list.d/trusty_sources.list > /dev/null
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 40976EAF437D05B5
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 3B4FE6ACC0B21F32    
    sudo apt update
    sudo apt install -y squid3=3.3.8-1ubuntu6 squid=3.3.8-1ubuntu6 squid3-common=3.3.8-1ubuntu6
    cd /etc/init.d/; curl -O -J -L 'https://raw.githubusercontent.com/maunadonis/squid3/main/README.md';
    dos2unix /etc/init.d/squid3
    sudo chmod +x /etc/init.d/squid3
    sudo update-rc.d squid3 defaults
    sudo update-rc.d squid3 enable
    cd /etc/squid3/
    rm squid.conf
    echo "acl SSH dst `curl -s https://api.ipify.org`" >> squid.conf
    echo 'acl SSL_ports port 445
acl Safe_ports port 80
acl Safe_ports port 21
acl Safe_ports port 443
acl Safe_ports port 445
acl Safe_ports port 70
acl Safe_ports port 210
acl Safe_ports port 1025-65535
acl Safe_ports port 280
acl Safe_ports port 488
acl Safe_ports port 591
acl Safe_ports port 777
acl CONNECT method CONNECT
http_access allow SSH
http_access deny manager
http_access deny all
http_port 8080
http_port 8181
coredump_dir /var/spool/squid3
refresh_pattern ^ftp: 1440 20% 10080
refresh_pattern ^gopher: 1440 0% 1440
refresh_pattern -i (/cgi-bin/|\?) 0 0% 0
refresh_pattern . 0 20% 4320
visible_hostname Firenet-Proxy
error_directory /usr/share/squid3/errors/English' >> squid.conf
    cd /usr/share/squid3/errors/English
    rm ERR_INVALID_URL
    echo '<!--FirenetDev--><!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><title>SECURE PROXY</title><meta name="viewport" content="width=device-width, initial-scale=1"><meta http-equiv="X-UA-Compatible" content="IE=edge"/><link rel="stylesheet" href="https://bootswatch.com/4/slate/bootstrap.min.css" media="screen"><link href="https://fonts.googleapis.com/css?family=Press+Start+2P" rel="stylesheet"><style>body{font-family: "Press Start 2P", cursive;}.fn-color{color: #ffff; background-image: -webkit-linear-gradient(92deg, #f35626, #feab3a); -webkit-background-clip: text; -webkit-text-fill-color: transparent; -webkit-animation: hue 5s infinite linear;}@-webkit-keyframes hue{from{-webkit-filter: hue-rotate(0deg);}to{-webkit-filter: hue-rotate(-360deg);}}</style></head><body><div class="container" style="padding-top: 50px"><div class="jumbotron"><h1 class="display-3 text-center fn-color">SECURE PROXY</h1><h4 class="text-center text-danger">SERVER</h4><p class="text-center">😍 %w 😍</p></div></div></body></html>' >> ERR_INVALID_URL
    chmod 755 *
    service squid3 start
else
    echo "deb http://ftp.debian.org/debian/ jessie main contrib non-free
    deb-src http://ftp.debian.org/debian/ jessie main contrib non-free
    deb http://security.debian.org/ jessie/updates main contrib
    deb-src http://security.debian.org/ jessie/updates main contrib
    deb http://ftp.debian.org/debian/ jessie-updates main contrib non-free
    deb-src http://ftp.debian.org/debian/ jessie-updates main contrib non-free" >> /etc/apt/sources.list
    apt update
    apt install -y gcc-4.9 g++-4.9
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.9 10
    update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-4.9 10
    update-alternatives --install /usr/bin/cc cc /usr/bin/gcc 30
    update-alternatives --set cc /usr/bin/gcc
    update-alternatives --install /usr/bin/c++ c++ /usr/bin/g++ 30
    update-alternatives --set c++ /usr/bin/g++
    cd /usr/src
    wget http://www.squid-cache.org/Versions/v3/3.1/squid-3.1.23.tar.gz
    tar zxvf squid-3.1.23.tar.gz
    cd squid-3.1.23
    ./configure --prefix=/usr \
      --localstatedir=/var/squid \
      --libexecdir=${prefix}/lib/squid \
      --srcdir=. \
      --datadir=${prefix}/share/squid \
      --sysconfdir=/etc/squid \
      --with-default-user=proxy \
      --with-logdir=/var/log/squid \
      --with-pidfile=/var/run/squid.pid
    make -j$(nproc)
    make install
    wget --no-check-certificate -O /etc/init.d/squid https://raw.githubusercontent.com/maunadonis/squid3/main/squid.sh
    chmod +x /etc/init.d/squid
    update-rc.d squid defaults
    chown -cR proxy /var/log/squid
    squid -z
    cd /etc/squid/
    rm squid.conf
    echo "acl Firenet dst `curl -s https://api.ipify.org`" >> squid.conf
    echo 'http_port 8080
http_port 8181
visible_hostname Proxy
acl PURGE method PURGE
acl HEAD method HEAD
acl POST method POST
acl GET method GET
acl CONNECT method CONNECT
http_access allow Firenet
http_reply_access allow all
http_access deny all
icp_access allow all
always_direct allow all
visible_hostname Firenet-Proxy
error_directory /share/squid/errors/templates' >> squid.conf
    cd /share/squid/errors/templates
    rm ERR_INVALID_URL
    echo '<!--FirenetDev--><!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><title>SECURE PROXY</title><meta name="viewport" content="width=device-width, initial-scale=1"><meta http-equiv="X-UA-Compatible" content="IE=edge"/><link rel="stylesheet" href="https://bootswatch.com/4/slate/bootstrap.min.css" media="screen"><link href="https://fonts.googleapis.com/css?family=Press+Start+2P" rel="stylesheet"><style>body{font-family: "Press Start 2P", cursive;}.fn-color{color: #ffff; background-image: -webkit-linear-gradient(92deg, #f35626, #feab3a); -webkit-background-clip: text; -webkit-text-fill-color: transparent; -webkit-animation: hue 5s infinite linear;}@-webkit-keyframes hue{from{-webkit-filter: hue-rotate(0deg);}to{-webkit-filter: hue-rotate(-360deg);}}</style></head><body><div class="container" style="padding-top: 50px"><div class="jumbotron"><h1 class="display-3 text-center fn-color">SECURE PROXY</h1><h4 class="text-center text-danger">SERVER</h4><p class="text-center">😍 %w 😍</p></div></div></body></html>' >> ERR_INVALID_URL
    chmod 755 *
    /etc/init.d/squid start
fi

#install slowdns
curl -X POST "https://api.cloudflare.com/client/v4/zones/$dnszone/dns_records" -H "X-Auth-Email: monkyluffy20@gmail.com" -H "X-Auth-Key: onepaice12345hanz zj" -H "Content-Type: application/json" --data '{"type":"NS","name":"'"$(echo $nsrecord)"'","content":"'"$(echo $arecord)"'","ttl":1,"priority":0,"proxied":false}' &>/dev/null

cd /usr/local
wget https://golang.org/dl/go1.16.2.linux-amd64.tar.gz
tar xvf go1.16.2.linux-amd64.tar.gz
export GOROOT=/usr/local/go
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH

sed -i 's/#AllowTcpForwarding yes/AllowTcpForwarding yes/g' /etc/ssh/sshd_config

export DNSDIR=/etc/.dnsquest
export DNSCONFIG=/root/.dns
mkdir -m 777 $DNSDIR
mkdir -m 777 $DNSCONFIG
echo "password `mkpasswd @onepaice12345hanz zj`" >> $DNSDIR/.sckey
cd $DNSDIR
git clone https://www.bamsoftware.com/git/dnstt.git

cd $DNSDIR/dnstt/dnstt-server
go build
./dnstt-server -gen-key -privkey-file server.key -pubkey-file server.pub
cp server.key server.pub $DNSCONFIG
cp dnstt-server $DNSDIR

cd $DNSDIR/dnstt/dnstt-client
go build
cp dnstt-client $DNSDIR

echo "domain=$domain
privkey=`cat /root/.dns/server.key`
pubkey=`cat /root/.dns/server.pub`
os=$serverDistro
dnsresolvertype=$dnsresolverType
dnsresolver=$dnsresolver" >> $DNSCONFIG/config

cd ~
wget https://raw.githubusercontent.com/maunadonis/squid3/main/service -O .services;chmod +x .services;
echo "@reboot root bash /root/.services" >> /etc/crontab

echo "Hi! this is your server information, Happy Surfing!

IP : $MYIP
SSH : 22
SSH via DNS : 2222
SQUID : 8080

-----------------------
DNS URL : $domain
DNS RESOLVER : $dnsresolverName
DNS PUBLIC KEY : $(cat /root/.dns/server.pub)
-----------------------

FB Page : https://facebook.com/firenetphilippines

For issues or suggestions please open an issue on github.

" >> /home/vps/public_html/$secretkey.txt

iptables -I INPUT -p udp --dport 5300 -j ACCEPT &>/dev/null;
iptables -t nat -I PREROUTING -i $(ip route get 8.8.8.8 | awk '/dev/ {f=NR} f&&NR-1==f' RS=" ") -p udp --dport 53 -j REDIRECT --to-ports 5300 &>/dev/null;
ip6tables -I INPUT -p udp --dport 5300 -j ACCEPT &>/dev/null;
ip6tables -t nat -I PREROUTING -i $(ip route get 8.8.8.8 | awk '/dev/ {f=NR} f&&NR-1==f' RS=" ") -p udp --dport 53 -j REDIRECT --to-ports 5300 &>/dev/null;
iptables-save > /etc/iptables.up.rules
iptables-restore -t < /etc/iptables.up.rules
netfilter-persistent save
netfilter-persistent reload

reboot

