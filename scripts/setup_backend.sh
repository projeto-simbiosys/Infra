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
apt install -y default-jre default-jdk maven

# Clona o repositório
cd /home/ubuntu
git clone https://github.com/projeto-simbiosys/BackEnd.git

cd /home/ubuntu/BackEnd/src/main/resources/
iconv -f ISO-8859-1 -t UTF-8 application.properties -o application.properties
sed -i 's/jdbc:mysql:\/\/localhost/jdbc:mysql:\/\/10.0.0.245/' application.properties
sed -i 's/^spring\.datasource\.username=.*/spring.datasource.username=simbiosys/' application.properties

cd /home/ubuntu/BackEnd

LC_ALL=C sed -i 's/[\x80-\xFF]//g' pom.xml

# Gera o jar
mvn clean package

# Roda o artefato jar do java
java -jar target/*.jar
