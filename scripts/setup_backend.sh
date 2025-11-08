#!/bin/bash
set -e

# Atualiza pacotes
apt update -y
apt install -y java-openjdk-21-jre maven

# Clona o repositório
git clone https://github.com/projeto-simbiosys/BackEnd.git

cd BackEnd/src/main/resources/
iconv -f ISO-8859-1 -t UTF-8 application.properties -o application.properties
sed -i 's/jdbc:mysql:\/\/localhost/jdbc:mysql:\/\/10.0.0.245/' application.properties

cd ~/BackEnd

# Gera o jar
mvn clean package

# Roda o artefato jar do java
java -jar target/*.jar
