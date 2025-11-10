#!/bin/bash
set -ex

# Força uso de IPv4
echo 'Acquire::ForceIPv4 "true";' > /etc/apt/apt.conf.d/99force-ipv4

# Espera NAT estar pronto
until ping -c1 google.com &>/dev/null; do
  echo "Aguardando conectividade com a internet..."
  sleep 5
done

# Atualiza pacotes
apt update -y
apt install -y nginx nodejs npm

# Clona o repositório
cd /home/ubuntu
git clone https://github.com/projeto-simbiosys/FrontEnd.git
cd FrontEnd
git checkout development

# Instala dependências
npm install

# Cria o arquivo .env na raiz do projeto
touch .env

# Define variáveis que você quer adicionar
VAR1_NAME="VITE_URL_API"
VAR1_VALUE="/api"
VAR2_NAME="VITE_SUPABASE_SERVICE_ROLE"
VAR2_VALUE=""

# Adiciona as variáveis ao final do arquivo
echo "${VAR1_NAME}=${VAR1_VALUE}" >> ".env"
echo "${VAR2_NAME}=${VAR2_VALUE}" >> ".env"

echo "arquivo .env criado com sucesso!"

# Build do projeto
npm run build

# Copia para o diretório do Nginx
rm -rf /var/www/html/*
cp -r dist/* /var/www/html/

# Configura o Nginx como servidor e load balancer
cat <<EOF >/etc/nginx/sites-available/default
upstream backendapp {
    server 10.0.0.235:8082;
    server 10.0.0.236:8082;
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
        proxy_pass http://backendapp/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Reinicia o Nginx
systemctl reload nginx
