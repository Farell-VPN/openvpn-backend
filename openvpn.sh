#!/bin/bash

[[ -e $(which curl) ]] && grep -q "1.1.1.1" /etc/resolv.conf || { 
    echo "nameserver 1.1.1.1" | cat - /etc/resolv.conf >> /etc/resolv.conf.tmp && mv /etc/resolv.conf.tmp /etc/resolv.conf
}

clear
red='\e[1;31m'
green='\e[0;32m'
blue='\e[0;34m'
cyan='\e[0;36m'
cyanb='\e[46m'
white='\e[037;1m'
grey='\e[1;36m'
NC='\e[0m'
# ==================================================
# Lokasi Hosting Penyimpan autoscript
hosting="https://scvps.rerechanstore.eu.org"
domain=$(cat /etc/xray/domain)

# var installation
export DEBIAN_FRONTEND=noninteractive
OS=`uname -m`;
MYIP=$(wget -qO- icanhazip.com);
MYIP2="s/xxxxxxxxx/$MYIP/g";
ANU=$(ip -o $ANU -4 route show to default | awk '{print $5}');

# Install OpenVPN dan Easy-RSA
apt install openvpn -y
apt install openvpn easy-rsa -y
apt install unzip -y
apt install openssl iptables iptables-persistent -y
mkdir -p /etc/openvpn/server/easy-rsa/
cd /etc/openvpn/
wget https://github.com/praiman99/AutoScriptVPN-AIO/raw/Beginner/vpn.zip
unzip vpn.zip
rm -f vpn.zip
chown -R root:root /etc/openvpn/server/easy-rsa/

cd
mkdir -p /usr/lib/openvpn/
cp /usr/lib/x86_64-linux-gnu/openvpn/plugins/openvpn-plugin-auth-pam.so /usr/lib/openvpn/openvpn-plugin-auth-pam.so

# nano /etc/default/openvpn
sed -i 's/#AUTOSTART="all"/AUTOSTART="all"/g' /etc/default/openvpn

# restart openvpn dan cek status openvpn
systemctl enable --now openvpn-server@server-tcp-1194
systemctl enable --now openvpn-server@server-udp-2200
/etc/init.d/openvpn restart
/etc/init.d/openvpn status

# aktifkan ip4 forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf

# Buat config client TCP 1194
cat > /etc/openvpn/client-tcp-1194.ovpn <<-END
client
dev tun
proto tcp
setenv FRIENDLY_NAME "Beginner TCP"
remote xxxxxxxxx 1194
http-proxy xxxxxxxxx 3128
resolv-retry infinite
route-method exe
auth-user-pass
auth-nocache
nobind
persist-key
persist-tun
comp-lzo
verb 3
END

sed -i $MYIP2 /etc/openvpn/client-tcp-1194.ovpn;

# Buat config client UDP 2200
cat > /etc/openvpn/client-udp-2200.ovpn <<-END
client
dev tun
proto udp
setenv FRIENDLY_NAME "Beginner UDP"
remote xxxxxxxxx 3128
resolv-retry infinite
route-method exe
auth-user-pass
auth-nocache
nobind
persist-key
persist-tun
comp-lzo
verb 3
END

sed -i $MYIP2 /etc/openvpn/client-udp-2200.ovpn;

cd
# pada tulisan xxx ganti dengan alamat ip address VPS anda
/etc/init.d/openvpn restart

# masukkan certificatenya ke dalam config client TCP 1194
echo '<ca>' >> /etc/openvpn/client-tcp-1194.ovpn
cat /etc/openvpn/server/ca.crt >> /etc/openvpn/client-tcp-1194.ovpn
echo '</ca>' >> /etc/openvpn/client-tcp-1194.ovpn

# Copy config OpenVPN client ke home directory root agar mudah didownload ( TCP 1194 )
cp /etc/openvpn/client-tcp-1194.ovpn /var/www/html/client-tcp-1194.ovpn

# masukkan certificatenya ke dalam config client UDP 2200
echo '<ca>' >> /etc/openvpn/client-udp-2200.ovpn
cat /etc/openvpn/server/ca.crt >> /etc/openvpn/client-udp-2200.ovpn
echo '</ca>' >> /etc/openvpn/client-udp-2200.ovpn

# Copy config OpenVPN client ke home directory root agar mudah didownload ( UDP 2200 )
cp /etc/openvpn/client-udp-2200.ovpn /var/www/html/client-udp-2200.ovpn

    # Membuat arsip ZIP dari konfigurasi
    cd /var/www/html/
    zip FN-Project.zip client-tcp-1194.ovpn client-udp-2200.ovpn > /dev/null 2>&1
    cd

    # Membuat halaman HTML untuk mengunduh konfigurasi
    cat <<'EOF' > /var/www/html/index.html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <title>OVPN Config Download</title>
  <meta name="description" content="Server" />
  <meta content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" name="viewport" />
  <meta name="theme-color" content="#000000" />
  <link href="https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/4.3.1/css/bootstrap.min.css" rel="stylesheet">
  <style>
    body {
      font-family: 'Courier New', monospace;
      background-color: #f6f8fa;
      padding: 2em;
      color: #333;
    }
    h5 {
      font-weight: bold;
      color: #0366d6;
    }
    p, a {
      font-size: 16px;
      line-height: 1.6;
    }
    .badge {
      background-color: #0366d6;
      color: white;
    }
    .container {
      background-color: white;
      border-radius: 8px;
      padding: 20px;
      box-shadow: 0 1px 3px rgba(27,31,35,.12), 0 8px 24px rgba(27,31,35,.1);
    }
    .list-group-item {
      border: none;
      padding-left: 0;
      font-family: 'Courier New', monospace;
    }
    a {
      text-decoration: none;
      color: #0366d6;
    }
    a:hover {
      text-decoration: underline;
    }
    ul {
      list-style-type: none;
      padding: 0;
    }
  </style>
</head>
<body>
  <div class="container">
    <h5>Config List</h5>
    <ul>
      <li class="list-group-item d-flex justify-content-between align-items-center">
        <p>TCP <span class="badge">Android/iOS/PC/Modem</span></p>
        <a href="https://IP-ADDRESS/fn/client-tcp-1194.ovpn">Download</a>
      </li>
      <li class="list-group-item d-flex justify-content-between align-items-center">
        <p>UDP <span class="badge">Android/iOS/PC/Modem</span></p>
        <a href="https://IP-ADDRESS/fn/client-udp-2200.ovpn">Download</a>
      </li>
      <li class="list-group-item d-flex justify-content-between align-items-center">
        <p>ALL.zip <span class="badge">Android/iOS/PC/Modem</span></p>
        <a href="https://IP-ADDRESS/fn/FN-Project.zip">Download</a>
      </li>
    </ul>
  </div>
</body>
</html>
EOF

    sed -i "s|IP-ADDRESS|$domain|g" /var/www/html/index.html
    
#firewall untuk memperbolehkan akses UDP dan akses jalur TCP

iptables -t nat -I POSTROUTING -s 10.6.0.0/24 -o $ANU -j MASQUERADE
iptables -t nat -I POSTROUTING -s 10.7.0.0/24 -o $ANU -j MASQUERADE
iptables-save > /etc/iptables.up.rules
chmod +x /etc/iptables.up.rules

iptables-restore -t < /etc/iptables.up.rules
netfilter-persistent save
netfilter-persistent reload

# Restart service openvpn
systemctl daemon-reload
systemctl enable openvpn
systemctl start openvpn
/etc/init.d/openvpn restart

# Membuat File Zip OVPN
cd /var/www/html
zip openvpn.zip *.ovpn
cd

#Squid Proxy
apt install sudo -y
wget https://raw.githubusercontent.com/serverok/squid-proxy-installer/master/squid3-install.sh -O squid3-install.sh
sudo bash squid3-install.sh
rm -f squid3-install.sh

if [ -f /etc/squid/squid.conf ]; then
  cd /etc/squid
  find . -type f -name "*squid.conf*" -exec sed -i 's|http_access allow password|http_access allow all|g' {} +
  systemctl daemon-reload
  systemctl restart squid
else
  cd /etc/squid3
  find . -type f -name "*squid.conf*" -exec sed -i 's|http_access allow password|http_access allow all|g' {} +
  systemctl daemon-reload
  systemctl restart squid3
fi

#Setup Open HTTP Puncher
cd
wget -O ohp.sh "https://raw.githubusercontent.com/Farell-VPN/Backend-ssh/1.0/ohp.sh"
chmod ohp.sh
./ohp.sh
rm -f ohp.sh

cd

# Delete script
history -c
rm -f /root/*.sh
rm -f /root/install
rm -f /root/*install*
rm -f "$0"
