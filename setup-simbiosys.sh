#!/bin/bash

echo "🚀 Iniciando setup do sistema Simbiosys..."

apt update && apt upgrade -y
apt install -y default-jdk git

# Node.js
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs

# MySQL Server
DEBIAN_FRONTEND=noninteractive apt install -y mysql-server
systemctl enable mysql
systemctl start mysql

# MySQL user and DB
echo "🎯 Criando banco e usuário..."
mysql -u root <<EOF
CREATE USER IF NOT EXISTS 'Analista'@'localhost' IDENTIFIED BY 'urubu100';
GRANT ALL PRIVILEGES ON *.* TO 'Analista'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

# Clone repos
cd /home/$USER
git clone https://github.com/projeto-simbiosys/FrontEnd.git
git clone https://github.com/projeto-simbiosys/BackEnd.git
git clone https://github.com/projeto-simbiosys/Database.git

# Import SQL
mysql -u Analista -purubu100 < Database/banco.sql

# PM2
npm install -g pm2

# Frontend build
cd FrontEnd
npm install
npm run build

# Criar server.js
cat <<'EOF' > server.js
import express from 'express'
import path from 'path'
import { fileURLToPath } from 'url'

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)
const app = express()
const PORT = 3000

app.use(express.static(path.join(__dirname, 'dist')))
app.get('*', (_, res) => {
  res.sendFile(path.join(__dirname, 'dist', 'index.html'))
})
app.listen(PORT, () => {
  console.log(`Frontend rodando em http://localhost:\${PORT}`)
})
EOF

# Rodar frontend
pm2 start server.js --name frontend

# Backend build
cd ../BackEnd
./mvnw clean package
JAR_FILE=$(find target -name "*.jar" | head -n 1)
pm2 start "java -jar $JAR_FILE" --name backend

# Garantir que reinicie com o sistema
pm2 save
pm2 startup

echo "✅ Sistema Simbiosys implantado com sucesso!"
