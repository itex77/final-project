#!/bin/bash

mkdir /etc/openvpn/easy-rsa
cp -R /usr/share/easy-rsa /etc/openvpn/
cd /etc/openvpn/easy-rsa/
./easyrsa init-pki
./easyrsa build-ca

ServerName=zabbix
DomainName=sf-admin-gusevnv.local
VPNNetwork='10.1.1.0 255.255.255.0'
NameServer=10.1.1.6
./easyrsa gen-dh

./easyrsa build-server-full $ServerName nopass

cp /etc/openvpn/easy-rsa/pki/dh.pem /etc/openvpn/
cp /etc/openvpn/easy-rsa/pki/issued/$ServerName.crt /etc/openvpn/
cp /etc/openvpn/easy-rsa/pki/private/$ServerName.key /etc/openvpn/
cp /etc/openvpn/easy-rsa/pki/ca.crt /etc/openvpn/

bash -c "cat > /etc/openvpn/$ServerName.conf <<EOF
port 1194
proto tcp
dev tun
ca ca.crt
cert $ServerName.crt
key $ServerName.key
dh dh.pem
ifconfig-pool-persist ipp.txt
server $VPNNetwork
push \"dhcp-option DNS $NameServer\"
push \"dhcp-option DOMAIN $DomainName\"
keepalive 10 120
cipher DES-CBC
persist-key
persist-tun
script-security 2
client-connect "/etc/openvpn/setdns.sh"
client-to-client
status /var/log/openvpn/$ServerName.log
EOF"

cd
cp setdns.sh /etc/openvpn/
chmod +x /etc/openvpn/setdns.sh

systemctl start openvpn@$ServerName
systemctl enable openvpn@$ServerName

unset ServerName
unset DomainName
unset VPNNetwork
unset NameServer

