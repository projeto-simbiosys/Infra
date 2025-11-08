#!/bin/bash
set -e

mkdir antesdoaptupdateeinstallegitclone

# Atualiza pacotes
apt update -y
apt install -y nginx nodejs npm

# Clona o repositório
git clone https://github.com/projeto-simbiosys/FrontEnd.git
cd FrontEnd
git checkout development

mkdir depoisdoaptupdateeinstallegitclone

# Gera o build
npm install
npm run build

# Copia para o diretório do Nginx
rm -rf /var/www/html/*
cp -r dist/* /var/www/html/

# Configura o Nginx como servidor e load balancer
cat <<EOF >/etc/nginx/sites-available/default
upstream backendapp {
    server 10.0.0.235:8080;
    server 10.0.0.236:8080;
}

server {
    listen 8080;
    server_name _;

    root /var/www/html;
    index index.html;

    location / {
        try_files \$uri /index.html;
    }

    location /api/ {
        proxy_pass http://backendapp;
    }
}
EOF

# Reinicia o Nginx
systemctl restart nginx
