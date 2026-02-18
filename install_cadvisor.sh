#!/bin/bash

GREEN="\e[32m"
RED="\e[31m"
BLUE="\e[34m"
YELLOW="\e[33m"
NC="\e[0m"

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}   🚀 Installing cAdvisor...          ${NC}"
echo -e "${BLUE}======================================${NC}"

# Check Docker
if ! command -v docker &> /dev/null
then
    echo -e "${RED}❌ Docker is not installed!${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Docker found${NC}"

# Remove old container if exists
if docker ps -a | grep -q cadvisor; then
    echo -e "${YELLOW}⚠️  Existing cAdvisor container found. Removing...${NC}"
    docker rm -f cadvisor
fi

echo -e "${BLUE}📦 Pulling cAdvisor image...${NC}"
docker pull ghcr.io/google/cadvisor:v0.53.0

echo -e "${BLUE}🐳 Running cAdvisor container...${NC}"
docker run -d \
  --name=cadvisor \
  --volume=/:/rootfs:ro \
  --volume=/var/run:/var/run:ro \
  --volume=/sys:/sys:ro \
  --volume=/var/lib/docker/:/var/lib/docker:ro \
  --volume=/dev/disk/:/dev/disk:ro \
  --publish=8080:8080 \
  --privileged \
  --device=/dev/kmsg \
  --restart=always \
  ghcr.io/google/cadvisor:v0.53.0

sleep 3

echo -e "${BLUE}🔍 Verifying container...${NC}"
if docker ps | grep -q cadvisor; then
    echo -e "${GREEN}✅ cAdvisor is running successfully!${NC}"
else
    echo -e "${RED}❌ cAdvisor failed to start${NC}"
    exit 1
fi

echo -e "${BLUE}📊 Checking metrics endpoint...${NC}"
if curl -s http://localhost:8080/metrics > /dev/null; then
    echo -e "${GREEN}✅ Metrics endpoint is accessible${NC}"
else
    echo -e "${RED}❌ Metrics endpoint not reachable${NC}"
fi

IP=$(hostname -I | awk '{print $1}')

echo -e "${GREEN}"
echo "======================================"
echo " 🎉 cAdvisor Installed Successfully! "
echo "======================================"
echo " 🌐 Web UI:      http://$IP:8080"
echo " 📈 Metrics:     http://$IP:8080/metrics"
echo " 🐳 Container:   cadvisor"
echo "======================================"
echo -e "${NC}"
