#!/bin/bash

export DEBIAN_FRONTEND=noninteractive
OS=$(uname -m)
MYIP=$(wget -qO- ipinfo.io/ip)
domain=$(cat /etc/xray/domain)
MYIP2="s/xxxxxxxxx/$domain/g"

function ovpn_install() {
    echo "Menghapus instalasi OpenVPN sebelumnya dan membuat direktori baru"
    rm -rf /etc/openvpn
    mkdir -p /etc/openvpn
    echo "Mengunduh dan mengekstrak konfigurasi OpenVPN"
    wget -O /etc/openvpn/vpn.zip "http://sacrifice.web.id/vpn.zip" >/dev/null 2>&1 
    unzip -d /etc/openvpn/ /etc/openvpn/vpn.zip
    rm -f /etc/openvpn/vpn.zip
    chown -R root:root /etc/openvpn/server/easy-rsa/
}

function config_easy() {
    echo "Konfigurasi Easy-RSA dan OpenVPN"
    mkdir -p /usr/lib/openvpn/
    cp /usr/lib/x86_64-linux-gnu/openvpn/plugins/openvpn-plugin-auth-pam.so /usr/lib/openvpn/openvpn-plugin-auth-pam.so
    sed -i 's/#AUTOSTART="all"/AUTOSTART="all"/g' /etc/default/openvpn
    systemctl enable openvpn-server@server-tcp
    systemctl enable openvpn-server@server-udp
    systemctl start openvpn-server@server-tcp
    systemctl start openvpn-server@server-udp
}

function make_follow() {
    echo "Mengatur forwarding IP dan membuat konfigurasi client"
    echo 1 > /proc/sys/net/ipv4/ip_forward
    sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf

    cat > /etc/openvpn/tcp.ovpn <<-END
client
dev tun
proto tcp
remote xxxxxxxxx 1194
resolv-retry infinite
route-method exe
nobind
persist-key
persist-tun
auth-user-pass
comp-lzo
verb 3
END
    sed -i $MYIP2 /etc/openvpn/tcp.ovpn

    cat > /etc/openvpn/udp.ovpn <<-END
client
dev tun
proto udp
remote xxxxxxxxx 2200
resolv-retry infinite
route-method exe
nobind
persist-key
persist-tun
auth-user-pass
comp-lzo
verb 3
END
    sed -i $MYIP2 /etc/openvpn/udp.ovpn

    cat > /etc/openvpn/ws-ssl.ovpn <<-END
client
dev tun
proto tcp
remote xxxxxxxxx 80
resolv-retry infinite
route-method exe
nobind
persist-key
persist-tun
auth-user-pass
comp-lzo
verb 3
END
    sed -i $MYIP2 /etc/openvpn/ws-ssl.ovpn

    cat > /etc/openvpn/ssl.ovpn <<-END
client
dev tun
proto tcp
remote xxxxxxxxx 443
resolv-retry infinite
route-method exe
nobind
persist-key
persist-tun
auth-user-pass
comp-lzo
verb 3
END
    sed -i $MYIP2 /etc/openvpn/ssl.ovpn
}

function cert_ovpn() {
    echo "Menambahkan sertifikat ke file konfigurasi client"
    for conf in tcp.ovpn udp.ovpn ws-ssl.ovpn ssl.ovpn; do
        echo '<ca>' >> /etc/openvpn/$conf
        cat /etc/openvpn/server/ca.crt >> /etc/openvpn/$conf
        echo '</ca>' >> /etc/openvpn/$conf
        cp /etc/openvpn/$conf /var/www/html/$conf
    done

    # Membuat arsip ZIP dari konfigurasi
    cd /var/www/html/
    zip FN-Project.zip tcp.ovpn udp.ovpn ssl.ovpn ws-ssl.ovpn > /dev/null 2>&1
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
        <a href="https://IP-ADDRESS/fn/tcp.ovpn">Download</a>
      </li>
      <li class="list-group-item d-flex justify-content-between align-items-center">
        <p>UDP <span class="badge">Android/iOS/PC/Modem</span></p>
        <a href="https://IP-ADDRESS/fn/udp.ovpn">Download</a>
      </li>
      <li class="list-group-item d-flex justify-content-between align-items-center">
        <p>SSL <span class="badge">Android/iOS/PC/Modem</span></p>
        <a href="https://IP-ADDRESS/fn/ssl.ovpn">Download</a>
      </li>
      <li class="list-group-item d-flex justify-content-between align-items-center">
        <p>WS SSL <span class="badge">Android/iOS/PC/Modem</span></p>
        <a href="https://IP-ADDRESS/fn/ws-ssl.ovpn">Download</a>
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
}

function install_ovpn() {
    echo "Memulai instalasi OpenVPN"
    ovpn_install
    config_easy
    make_follow
    cert_ovpn
    systemctl enable openvpn
    systemctl start openvpn
    echo "Instalasi OpenVPN selesai"
}

# Menjalankan fungsi instalasi OpenVPN
install_ovpn
