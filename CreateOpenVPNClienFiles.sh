#!/bin/bash
ClientListFile=`pwd`'/ClientList'
ServerAddress=`ip a | grep eth0 | grep inet | sed 's/ *inet *//' | sed -r 's/\/.+//'`
cd /etc/openvpn/easy-rsa/
while read ClientName
do
  if [ "$ClientName" != "" ]
  then
    echo $ClientName
    ./easyrsa build-client-full $ClientName nopass
    mkdir -p /etc/openvpn/clients/$ClientName
    cp /etc/openvpn/easy-rsa/pki/ca.crt /etc/openvpn/clients/$ClientName/
    cp /etc/openvpn/easy-rsa/pki/issued/$ClientName.crt /etc/openvpn/clients/$ClientName/
    cp /etc/openvpn/easy-rsa/pki/private/$ClientName.key /etc/openvpn/clients/$ClientName/
    bash -c "cat > /etc/openvpn/clients/$ClientName/$ClientName.conf <<EOF
client
dev tun
proto tcp
remote $ServerAddress
resolv-retry infinite
nobind
persist-key
persist-tun
cipher DES-CBC
script-security 2
up /etc/openvpn/update-systemd-resolved
up-restart
down /etc/openvpn/update-systemd-resolved
down-pre
<ca>
EOF"

    cat /etc/openvpn/clients/$ClientName/ca.crt >> /etc/openvpn/clients/$ClientName/$ClientName.conf
    echo \</ca\> >> /etc/openvpn/clients/$ClientName/$ClientName.conf
    echo \<cert\> >> /etc/openvpn/clients/$ClientName/$ClientName.conf
    cat /etc/openvpn/clients/$ClientName/$ClientName.crt >> /etc/openvpn/clients/$ClientName/$ClientName.conf
    echo \<\/cert\> >> /etc/openvpn/clients/$ClientName/$ClientName.conf
    echo \<key\> >> /etc/openvpn/clients/$ClientName/$ClientName.conf
    cat /etc/openvpn/clients/$ClientName/$ClientName.key >> /etc/openvpn/clients/$ClientName/$ClientName.conf
    echo \<\/key\> >> /etc/openvpn/clients/$ClientName/$ClientName.conf



  fi
done < $ClientListFile
