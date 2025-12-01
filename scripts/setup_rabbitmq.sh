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
sudo apt update -y

sudo apt install docker.io -y

sudo usermod -a -G docker $(whoami)

sudo systemctl start docker

sudo docker network create rabbit-network

sudo docker pull castrito/simbiosys-consumer-rabbitmq:latest
sudo docker pull rabbitmq:3.13-management

sudo docker run -d --name rabbitmq --network rabbit-network -p 5672:5672 -p 15672:15672 --restart always rabbitmq:3.13-management

sudo docker run -d --name simbiosys_consumer_rabbitmq --network rabbit-network -p 8082:8082 --restart always castrito/simbiosys-consumer-rabbitmq:latest
