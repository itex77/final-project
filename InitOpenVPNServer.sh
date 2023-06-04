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

echo net.ipv4.ip_forward=1 >> /etc/sysctl.conf
sysctl -p


sudo ufw allow 1194/udp

bash -c "cat > /etc/ufw/before.rules <<EOF
 # don't delete the 'COMMIT' line or these rules won't be processed
 COMMIT
+# START OPENVPN RULES
+# NAT table rules
+*nat
+:POSTROUTING ACCEPT [0:0]
+# Allow traffic from OpenVPN client to eth0
+-A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
+COMMIT
+# END OPENVPN RULES
EOF"
