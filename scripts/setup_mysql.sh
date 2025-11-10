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
apt install -y mysql-server
sudo sed -i 's/^bind-address\s*=.*/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf

systemctl restart mysql


# Clona o repositório
cd /home/ubuntu
git clone https://github.com/projeto-simbiosys/Database.git
cd Database
git checkout agnostic-script

MYSQL_USER="simbiosys"
MYSQL_SENHA="0310kaka"

sudo mysql <<EOF
CREATE USER "${MYSQL_USER}"@'10.0.0.235' IDENTIFIED BY "${MYSQL_SENHA}";
CREATE USER "${MYSQL_USER}"@'10.0.0.236' IDENTIFIED BY "${MYSQL_SENHA}";

GRANT ALL PRIVILEGES ON SIMBIOSYS.* TO "${MYSQL_USER}"@'10.0.0.235';
GRANT ALL PRIVILEGES ON SIMBIOSYS.* TO "${MYSQL_USER}"@'10.0.0.236';
FLUSH PRIVILEGES;
EOF

echo "Senha do root alterada com sucesso!"

# Roda o script de criação do banco de dados
sudo mysql < Banco-Script.sql
