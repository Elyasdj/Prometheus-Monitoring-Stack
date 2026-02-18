#!/bin/bash
set -e

GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
BLUE="\e[34m"
NC="\e[0m"

USER="exporter"
BIN_PATH="/usr/local/bin/node_exporter"
SERVICE_FILE="/usr/lib/systemd/system/node_exporter.service"
SCRIPT_NAME=$(basename "$0")

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}   🚀 Offline Node Exporter Installer    ${NC}"
echo -e "${BLUE}=========================================${NC}"

ARCHIVE=$(ls node_exporter-*.linux-*.tar.gz 2>/dev/null | head -n1)
if [[ -z "$ARCHIVE" ]]; then
    echo -e "${RED}❌ No node_exporter archive found${NC}"
    echo -e "${YELLOW}Expected: node_exporter-<version>.linux-<arch>.tar.gz${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Found archive: $ARCHIVE${NC}"

#########################################
#               Extract                 #
#########################################

VERSION=$(echo "$ARCHIVE" | sed -E 's/node_exporter-([0-9.]+)\.linux-.*/\1/')
ARCH=$(echo "$ARCHIVE" | sed -E 's/.*\.linux-([^.]+)\.tar\.gz/\1/')
DIR="node_exporter-${VERSION}.linux-${ARCH}"

echo -e "${GREEN}📦 Version: $VERSION${NC}"
echo -e "${GREEN}🖥 Architecture: $ARCH${NC}"

echo -e "${BLUE}📂 Extracting archive...${NC}"
tar -xvf "$ARCHIVE" >/dev/null
echo -e "${GREEN}✅ Archive extracted${NC}"

#########################################
#              Create user              #
#########################################

echo -e "${BLUE}👤 Creating user: $USER${NC}"
if ! id $USER &>/dev/null; then
    useradd -rs /sbin/nologin $USER
    echo -e "${GREEN}✅ User created${NC}"
else
    echo -e "${YELLOW}⚠️ User already exists${NC}"
fi

#########################################
#            Install binary             #
#########################################

echo -e "${BLUE}⚙️ Installing binary...${NC}"

# ✅ FIX: ensure destination directory exists
mkdir -p "$(dirname "$BIN_PATH")"

mv "$DIR/node_exporter" "$BIN_PATH"
chown $USER:$USER "$BIN_PATH"
chmod 755 "$BIN_PATH"
echo -e "${GREEN}✅ Binary installed at $BIN_PATH${NC}"

#########################################
#         Create systemd service        #
#########################################

echo -e "${BLUE}📝 Creating systemd service...${NC}"
cat <<EOF > "$SERVICE_FILE"
[Unit]
Description=Prometheus Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=$USER
Group=$USER
Type=simple
ExecStart=$BIN_PATH

[Install]
WantedBy=multi-user.target
EOF
echo -e "${GREEN}✅ Service file created at $SERVICE_FILE${NC}"

echo -e "${BLUE}🔄 Reloading systemd...${NC}"
systemctl daemon-reexec
systemctl daemon-reload

echo -e "${BLUE}▶️ Enabling and starting service...${NC}"
systemctl enable --now node_exporter

#########################################
#          Minimal status check         #
#########################################

echo -e "${BLUE}🔍 Verifying service...${NC}"
systemctl is-active --quiet node_exporter && \
echo -e "${GREEN}✅ SERVICE: UP${NC}" || \
echo -e "${RED}❌ SERVICE: DOWN${NC}"

ss -tunlp | grep -q ":9100" && \
echo -e "${GREEN}✅ PORT 9100: LISTENING${NC}" || \
echo -e "${RED}❌ PORT 9100: NOT LISTENING${NC}"

IP=$(hostname -I | awk '{print $1}')

echo -e "${GREEN}"
echo "===================================================="
echo "      🎉 Node Exporter Installed Successfully       "
echo "===================================================="
echo " 🌐 Metrics URL: http://$IP:9100/metrics"
echo " 📦 Version:     $VERSION"
echo " 🖥  Arch:        $ARCH"
echo " 👤 User:        $USER"
echo " ⚙  Binary:      $BIN_PATH"
echo "===================================================="
echo -e "${NC}"

#########################################
#               Clean Up                #
#########################################

echo -e "${BLUE}🧹 Cleaning up archive, extracted dir, and script...${NC}"
rm -rf "$ARCHIVE" "$DIR" "$SCRIPT_NAME"
echo -e "${GREEN}✅ Cleanup completed${NC}"
