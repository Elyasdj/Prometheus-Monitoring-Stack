#!/bin/bash

set -e

NODE_EXPORTER_VERSION="1.10.2"
ARCHIVE="node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"
DIR="node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64"
BIN_PATH="/usr/local/bin/node_exporter"
SERVICE_FILE="/usr/lib/systemd/system/node_exporter.service"

# Check archive exists
if [[ ! -f "$ARCHIVE" ]]; then
    echo "❌ File $ARCHIVE not found in current directory"
    exit 1
fi

echo "==> Extracting Node Exporter"
tar -xvf "$ARCHIVE"

echo "==> Creating exporter user"
if ! id exporter &>/dev/null; then
    useradd -rs /sbin/nologin exporter
fi

echo "==> Installing binary"
mv "$DIR/node_exporter" "$BIN_PATH"
chown exporter:exporter "$BIN_PATH"
chmod 755 "$BIN_PATH"

echo "==> Creating systemd service"
cat <<EOF > "$SERVICE_FILE"
[Unit]
Description=Prometheus Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=exporter
Group=exporter
Type=simple
ExecStart=$BIN_PATH

[Install]
WantedBy=multi-user.target
EOF

echo "==> Reloading systemd"
systemctl daemon-reexec
systemctl daemon-reload

echo "==> Configuring firewall (port 9100)"
if systemctl is-active --quiet firewalld; then
    firewall-cmd --add-port=9100/tcp --permanent
    firewall-cmd --reload
else
    echo "⚠️ firewalld is not running, skipping firewall step"
fi

echo "==> Enabling and starting service"
systemctl enable --now node_exporter.service

echo "==> Verification"
systemctl status node_exporter.service --no-pager
ss -tunpla | grep 9100 || echo "⚠️ Port 9100 is not listening"

echo "==> Cleaning up installation files"
rm -rf "$ARCHIVE" "$DIR"

echo "🧹 Cleanup completed"
echo "✅ Node Exporter installed successfully"
