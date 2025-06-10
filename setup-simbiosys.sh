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
DATABASE_SCRIPT="Banco-Script.sql"

echo "🚀 Iniciando a instalação e implantação..."

# Etapa 1: Atualizar o sistema e instalar pacotes essenciais
echo "📦 Atualizando sistema e instalando dependências..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y git curl gnupg build-essential mysql-server maven unzip

# Etapa 2: Instalar Java 21
echo "☕ Instalando Java 21..."
sudo add-apt-repository ppa:openjdk-r/ppa -y
sudo apt update
sudo apt install -y openjdk-21-jdk
java -version

# Etapa 3: Instalar Node.js 20 e PM2
echo "🌐 Instalando Node.js e PM2..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
sudo npm install -g pm2 serve

# Etapa 4: Clonar os repositórios
cd /home/$VM_USER
echo "📁 Clonando repositórios..."
git clone $BACKEND_REPO
git clone $FRONTEND_REPO
cd FrontEnd && git checkout $FRONTEND_BRANCH && cd ..
git clone $DATABASE_REPO

# Etapa 5: Configurar banco de dados
echo "🛢️ Configurando MySQL..."
sudo systemctl start mysql
sudo mysql <<EOF
CREATE DATABASE IF NOT EXISTS $MYSQL_DB;
CREATE USER IF NOT EXISTS '$MYSQL_USER'@'localhost' IDENTIFIED BY '$MYSQL_PASS';
GRANT ALL PRIVILEGES ON $MYSQL_DB.* TO '$MYSQL_USER'@'localhost';
FLUSH PRIVILEGES;
EOF

# Popular banco de dados
if [ -f "/home/$VM_USER/Database/$DATABASE_SCRIPT" ]; then
    echo "📥 Importando script SQL..."
    mysql -u $MYSQL_USER -p$MYSQL_PASS $MYSQL_DB < /home/$VM_USER/Database/$DATABASE_SCRIPT
else
    echo "⚠️ Script de banco de dados não encontrado."
fi

# Etapa 6: Corrigir application.properties se necessário
echo "🧹 Corrigindo application.properties..."
cd /home/$VM_USER/BackEnd
iconv -f ISO-8859-1 -t UTF-8 src/main/resources/application.properties -o src/main/resources/application.properties.utf8
mv src/main/resources/application.properties.utf8 src/main/resources/application.properties

# Etapa 7: Build do BackEnd
echo "⚙️ Compilando o backend com Maven (Java 21)..."
./mvnw clean package -DskipTests

# Etapa 8: Corrigir import quebrado do FrontEnd
echo "🧠 Corrigindo import do CardKPI..."
sed -i 's:from "../../components/CardKPI":from "../../components/CardKPI/index.jsx":g' /home/$VM_USER/FrontEnd/src/pages/Dashboard/index.jsx

# Etapa 9: Build do FrontEnd
echo "🏗️ Buildando o front..."
cd /home/$VM_USER/FrontEnd
rm -rf node_modules package-lock.json dist
npm install
npm run build

# Etapa 10: Iniciar com PM2
echo "🚀 Iniciando serviços com PM2..."
pm2 delete all
pm2 start "java -jar /home/$VM_USER/BackEnd/target/*.jar" --name backend
pm2 start "serve -s dist -l 3000" --name frontend
pm2 save

# Etapa 11: Configurar PM2 no boot
echo "🧩 Configurando PM2 para iniciar com o sistema..."
pm2 startup systemd -u $VM_USER --hp /home/$VM_USER | sudo bash

echo -e "\n✅ Implantação concluída com sucesso!"
echo "🌐 Frontend: http://SEU_IP:3000"
echo "☕ Backend:  http://SEU_IP:8080"
echo "📋 Verifique com: pm2 list"



