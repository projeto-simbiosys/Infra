#!/bin/bash

# Variáveis
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
echo "🔄 Clonando repositórios..."
cd /home/$VM_USER
git clone $BACKEND_REPO
git clone $FRONTEND_REPO
cd FrontEnd
git checkout $FRONTEND_BRANCH
cd ..
git clone $DATABASE_REPO

# --- Etapa 2: Instalar dependências ---
echo "📦 Instalando dependências..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y openjdk-17-jdk maven mysql-server git curl gnupg

curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
sudo npm install -g pm2 serve

# --- Etapa 3: Banco de dados ---
echo "🛢️ Configurando banco de dados..."
sudo mysql <<EOF
CREATE DATABASE IF NOT EXISTS $MYSQL_DB;
CREATE USER IF NOT EXISTS '$MYSQL_USER'@'localhost' IDENTIFIED BY '$MYSQL_PASS';
GRANT ALL PRIVILEGES ON $MYSQL_DB.* TO '$MYSQL_USER'@'localhost';
FLUSH PRIVILEGES;
EOF

if [ -f "/home/$VM_USER/Database/$DATABASE_SCRIPT_FILE" ]; then
    echo "📥 Populando banco com $DATABASE_SCRIPT_FILE"
    mysql -u $MYSQL_USER -p$MYSQL_PASS $MYSQL_DB < /home/$VM_USER/Database/$DATABASE_SCRIPT_FILE
else
    echo "⚠️ Banco de dados não populado. Script não encontrado."
fi

# --- Etapa 4: Backend ---
echo "☕ Compilando backend..."
cd /home/$VM_USER/BackEnd
chmod +x mvnw

# Corrigir encoding se necessário:
iconv -f ISO-8859-1 -t UTF-8 src/main/resources/application.properties -o src/main/resources/application.properties.utf8 && \
mv src/main/resources/application.properties.utf8 src/main/resources/application.properties

./mvnw clean package -DskipTests

pm2 start "java -jar target/*.jar" --name backend
pm2 save

# --- Etapa 5: Frontend ---
echo "🌐 Buildando frontend..."
cd /home/$VM_USER/FrontEnd
rm -rf node_modules package-lock.json
npm install
npm run build

pm2 start "serve -s dist -l 3000" --name frontend
pm2 save

# --- Etapa 6: PM2 startup ---
echo "⚙️ Configurando PM2 no boot..."
pm2 startup systemd -u $VM_USER --hp /home/$VM_USER

echo -e "\n✅ Implantação concluída!"
echo "Acesse o Frontend em: http://SEU_IP:3000"
echo "Acesse o Backend em: http://SEU_IP:8080"
echo "Use 'pm2 list' para verificar o status."


