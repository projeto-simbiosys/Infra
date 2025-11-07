#!/bin/bash
set -e

apt update -y
apt upgrade -y
apt install -y nginx

# Configura proxy reverso
cat > /etc/nginx/sites-available/default <<EOL
upstream webapp {
    server 10.0.0.135:8080;
    server 10.0.0.136:8080;
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

systemctl restart nginx
