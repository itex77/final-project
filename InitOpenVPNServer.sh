#!/bin/bash

mkdir -p /etc/openvpn/keys
mkdir /etc/openvpn/easy-rsa
cd /etc/openvpn/easy-rsa/
cp -r /usr/share/easy-rsa/* .

sudo bash -c 'cat > /etc/openvpn/easy-rsa/vars <<EOF
export KEY_COUNTRY="RU"
export KEY_PROVINCE="Tatarstan"
export KEY_CITY="Kazan"
export KEY_ORG="SKILLFACTORY"
export KEY_EMAIL="info@corp.org"
export KEY_OU="corp"
EOF'

./easyrsa init-pki
./easyrsa build-ca

ServerName=ub1srv
VPNNetwork='10.8.0.0 255.255.255.0'

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
ca keys/ca.crt
cert keys/$ServerName.crt
key keys/$ServerName.key
dh keys/dh.pem
server $VPNNetwork
ifconfig-pool-persist ipp.txt
keepalive 10 120
persist-key
persist-tun
script-security 2
status /var/log/openvpn/openvpn-status.log
log-append /var/log/openvpn/openvpn.log
cipher DES-CBC
EOF'

mkdir /var/log/openvpn

systemctl start openvpn@$ServerName
systemctl enable openvpn@$ServerName

unset ServerName
unset VPNNetwork


