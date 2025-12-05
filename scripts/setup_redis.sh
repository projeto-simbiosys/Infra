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

sudo docker network create redis-net

sudo docker volume create redis_data
sudo docker volume create redisinsight_data

sudo docker run -d --name simbiosys --network redis-net -p 6379:6379 -v redis_data:/data redis:7-alpine redis-server --maxmemory 512mb --maxmemory-policy allkeys-lfu --save 60 1 --loglevel warning

sudo docker run -d --name redisinsight --network redis-net -p 5540:5540 -v redisinsight_data:/data redis/redisinsight:latest