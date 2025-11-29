#!/bin/bash
set -ex

# Força uso de IPv4
echo 'Acquire::ForceIPv4 "true";' > /etc/apt/apt.conf.d/99force-ipv4

# Espera NAT estar pronto
until ping -c1 google.com &>/dev/null; do
  echo "Aguardando conectividade com a internet..."
  sleep 5
done

apt update -y
apt install -y nginx

# Configura proxy reverso
cat > /etc/nginx/sites-available/default <<EOL
upstream webapp {
    server 10.0.0.135:80;
    server 10.0.0.136:80;
}

server {
    listen 8080;

    location / {
        proxy_pass http://webapp;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOL

systemctl reload nginx
