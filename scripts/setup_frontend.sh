#!/bin/bash
set -ex

# Força uso de IPv4
echo 'Acquire::ForceIPv4 "true";' > /etc/apt/apt.conf.d/99force-ipv4

# Espera NAT estar pronto
until ping -c1 google.com &>/dev/null; do
  echo "Aguardando conectividade com a internet..."
  sleep 5
done

apt update -y
apt install docker.io -y

sudo usermod -a -G docker $(whoami)

sudo systemctl start docker

sudo docker pull castrito/simbiosys-front-end:latest

sudo docker run --name simbiosys-frontend -d -p 80:80 --restart always castrito/simbiosys-front-end:latest