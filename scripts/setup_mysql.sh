#!/bin/bash
set -e

# Atualiza pacotes
apt update -y
apt install -y sudo apt install mysql-server
systemctl start mysql

# Clona o repositório
git clone https://github.com/projeto-simbiosys/Database.git
cd Database
git checkout agnostic-script

# Roda o script de criação do banco de dados
sudo mysql < Banco-Script.sql
