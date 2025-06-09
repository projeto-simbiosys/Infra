#!/bin/bash

# Este script automatiza o processo de implantação do backend (Java Spring Boot) e frontend (Vite) em uma VM Ubuntu 22.04 na Azure.
# Ele assume que você já está conectado via SSH na VM e que a VM foi resetada ou criada do zero.

# --- Variáveis de Configuração ---
VM_USER="analista"
MYSQL_DB="SIMBIOSYS"
MYSQL_USER="Analista"
MYSQL_PASS="urubu100"
BACKEND_REPO="https://github.com/projeto-simbiosys/BackEnd.git"
FRONTEND_REPO="https://github.com/projeto-simbiosys/FrontEnd.git"
FRONTEND_BRANCH="development"
DATABASE_REPO="https://github.com/projeto-simbiosys/Database.git"
DATABASE_SCRIPT_FILE="Banco-Script.sql"

echo "Iniciando o processo de implantação..."

# --- Etapa 1: Baixar repositórios ---
echo "\n--- Baixando repositórios ---"
cd /home/$VM_USER
git clone $BACKEND_REPO
git clone $FRONTEND_REPO
cd FrontEnd
git checkout $FRONTEND_BRANCH
cd ..
git clone $DATABASE_REPO

# --- Etapa 2: Instalar dependências ---
echo "\n--- Atualizando o sistema e instalando dependências ---"
sudo apt update && sudo apt upgrade -y
sudo apt install -y openjdk-17-jdk maven mysql-server git curl gnupg

# Instalar Node.js + npm
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Instalar PM2
sudo npm install -g pm2

# --- Etapa 3: Banco de dados ---
echo "\n--- Configurando o banco de dados MySQL ---"
sudo mysql -e "CREATE DATABASE IF NOT EXISTS $MYSQL_DB;"
sudo mysql -e "CREATE USER IF NOT EXISTS \'$MYSQL_USER\'@\'localhost\' IDENTIFIED BY \'$MYSQL_PASS\';"
sudo mysql -e "GRANT ALL PRIVILEGES ON $MYSQL_DB.* TO \'$MYSQL_USER\'@\'localhost\';"
sudo mysql -e "FLUSH PRIVILEGES;"

# Popular banco de dados com o script do repositório Database
if [ -f "/home/$VM_USER/Database/$DATABASE_SCRIPT_FILE" ]; then
    echo "Populando o banco de dados com /home/$VM_USER/Database/$DATABASE_SCRIPT_FILE"
    mysql -u $MYSQL_USER -p$MYSQL_PASS $MYSQL_DB < /home/$VM_USER/Database/$DATABASE_SCRIPT_FILE
else
    echo "ERRO: O arquivo $DATABASE_SCRIPT_FILE não foi encontrado em /home/$VM_USER/Database/. O banco de dados não será populado automaticamente."
    echo "Por favor, verifique se o repositório Database foi clonado corretamente e se o arquivo está no local esperado."
    exit 1
fi

# --- Etapa 4: Backend (Spring Boot) ---
echo "\n--- Compilando e iniciando o Backend ---"
cd /home/$VM_USER/BackEnd
chmod +x mvnw # Garante que o script mvnw seja executável
./mvnw clean package -DskipTests

pm2 start "java -jar target/*.jar" --name backend
pm2 save

# --- Etapa 5: Frontend (Vite) ---
echo "\n--- Compilando e iniciando o Frontend ---"
cd /home/$VM_USER/FrontEnd
rm -rf node_modules package-lock.json # Limpeza para garantir instalação limpa
npm install
npm run build

# Instalar \'serve\' globalmente se ainda não estiver
sudo npm install -g serve

pm2 start "serve -s dist -l 3000" --name frontend
pm2 save

# --- Etapa 6: Configurar Startup (PM2) ---
echo "\n--- Configurando PM2 para iniciar no boot do sistema ---"
echo "O PM2 irá gerar um comando para você executar. Por favor, copie e cole o comando gerado abaixo para finalizar a configuração de startup."
pm2 startup systemd -u $VM_USER --hp /home/$VM_USER

echo "\n--- Implantação Concluída! ---"
echo "Verifique o status das suas aplicações com: pm2 list"
echo "Acesse o Frontend em: http://SEU_IP_DA_VM:3000"
echo "Acesse o Backend em: http://SEU_IP_DA_VM:8080"


