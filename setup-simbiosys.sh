#!/bin/bash
set -e # Sai imediatamente se um comando falhar
set -x # Imprime os comandos e seus argumentos conforme são executados

# Função para esperar pelo lock do apt
wait_for_apt_lock() {
    MAX_ATTEMPTS=10
    ATTEMPT=0
    while fuser /var/lib/dpkg/lock >/dev/null 2>&1 || fuser /var/lib/apt/lists/lock >/dev/null 2>&1 || fuser /var/cache/apt/archives/lock >/dev/null 2>&1;
    do
        if [ $ATTEMPT -ge $MAX_ATTEMPTS ]; then
            echo "Erro: Não foi possível obter o lock do apt após $MAX_ATTEMPTS tentativas. Por favor, verifique processos apt em execução e tente novamente."
            exit 1
        fi
        echo "Aguardando liberação do lock do apt... Tentativa $((ATTEMPT+1)) de $MAX_ATTEMPTS"
        sleep 10 # Espera 10 segundos antes de tentar novamente
        ATTEMPT=$((ATTEMPT+1))
    done
}

# Variáveis
VM_USER="analista"
MYSQL_DB="SIMBIOSYS"
MYSQL_USER="Analista"
MYSQL_PASS="urubu100"
BACKEND_REPO="https://github.com/projeto-simbiosys/BackEnd.git"
FRONTEND_REPO="https://github.com/projeto-simbiosys/FrontEnd.git"
FRONTEND_BRANCH="azure-aplicada" # Mantendo a branch do script fornecido pelo usuário
DATABASE_REPO="https://github.com/projeto-simbiosys/Database.git"
DATABASE_SCRIPT="Banco-Script.sql"

echo "🚀 Iniciando a instalação e implantação..."

# Etapa 1: Atualizar o sistema e instalar pacotes essenciais
echo "📦 Atualizando sistema e instalando dependências..."
wait_for_apt_lock
sudo DEBIAN_FRONTEND=noninteractive apt update && sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y
wait_for_apt_lock
sudo DEBIAN_FRONTEND=noninteractive apt install -y git curl gnupg build-essential mysql-server unzip maven

# Etapa 2: Instalar Java 21
echo "☕ Instalando Java 21..."
wait_for_apt_lock
sudo DEBIAN_FRONTEND=noninteractive add-apt-repository ppa:openjdk-r/ppa -y
wait_for_apt_lock
sudo DEBIAN_FRONTEND=noninteractive apt update
wait_for_apt_lock
sudo DEBIAN_FRONTEND=noninteractive apt install -y openjdk-21-jdk

# Confirmar Java 21
java -version

# Etapa 3: Instalar Node.js 20 e PM2
echo "🌐 Instalando Node.js e PM2..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
wait_for_apt_lock
sudo DEBIAN_FRONTEND=noninteractive apt install -y nodejs
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
CREATE USER IF NOT EXISTS 
\'$MYSQL_USER\'@\'$MYSQL_PASS\';
GRANT ALL PRIVILEGES ON $MYSQL_DB.* TO 
\'$MYSQL_USER\'@\'$MYSQL_PASS\';
FLUSH PRIVILEGES;
EOF

# Popular banco de dados - Removendo o comando CREATE DATABASE do script SQL antes de importar
if [ -f "/home/$VM_USER/Database/$DATABASE_SCRIPT" ]; then
    echo "📥 Importando script SQL (ignorando CREATE DATABASE)..."
    grep -v "^CREATE DATABASE" /home/$VM_USER/Database/$DATABASE_SCRIPT | mysql -u $MYSQL_USER -p$MYSQL_PASS $MYSQL_DB
else
    echo "⚠️ Script de banco de dados não encontrado."
fi

# Etapa 6: Corrigir application.properties se necessário
echo "🧹 Corrigindo application.properties (UTF-8)..."
cd /home/$VM_USER/BackEnd
iconv -f ISO-8859-1 -t UTF-8 src/main/resources/application.properties -o src/main/resources/application.properties.utf8
mv src/main/resources/application.properties.utf8 src/main/resources/application.properties

# Etapa 7: Build do BackEnd
echo "⚙️ Compilando o backend com Maven (Java 21)..."
cd /home/$VM_USER/BackEnd # Garante que estamos no diretório correto
chmod +x mvnw # Garante que o script mvnw seja executável
./mvnw clean package -DskipTests

# Etapa 8: Build do FrontEnd (branch correta)
echo "🏗️ Buildando o frontend..."
cd /home/$VM_USER/FrontEnd
rm -rf node_modules package-lock.json dist
npm install
npm run build

# Etapa 9: Iniciar com PM2
echo "🚀 Iniciando serviços com PM2..."
pm2 delete all
pm2 start "java -jar /home/$VM_USER/BackEnd/target/*.jar" --name backend
pm2 start "serve -s /home/$VM_USER/FrontEnd/dist -l 3000" --name frontend
pm2 save

# Etapa 10: Configurar PM2 no boot
echo "🧩 Configurando PM2 para iniciar com o sistema..."
pm2 startup systemd -u $VM_USER --hp /home/$VM_USER | sudo bash

echo -e "\n✅ Implantação concluída com sucesso!"
echo "🌐 Frontend: http://SEU_IP:3000"
echo "☕ Backend:  http://SEU_IP:8080"
echo "📋 Verifique com: pm2 list"


