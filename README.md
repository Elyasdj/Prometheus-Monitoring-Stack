# 📊 Prometheus Monitoring Stack - Complete Setup Guide

A comprehensive production-ready guide for deploying and configuring Prometheus monitoring infrastructure with exporters and Grafana visualization.

[![Prometheus](https://img.shields.io/badge/Prometheus-v3.5.0-orange?logo=prometheus)](https://prometheus.io/)
[![Grafana](https://img.shields.io/badge/Grafana-v12.2.1-orange?logo=grafana)](https://grafana.com/)

---

## 📑 Table of Contents

- [Introduction](#-introduction)
- [Core Concepts](#-core-concepts)
- [Architecture](#-architecture)
- [Prerequisites](#-prerequisites)
- [Installation & Configuration](#-installation--configuration)
  - [Prometheus Server](#1-prometheus-server)
  - [Node Exporter](#2-node-exporter)
  - [Blackbox Exporter](#3-blackbox-exporter)
  - [cAdvisor](#4-cadvisor)
  - [Grafana](#5-grafana)
- [Security Hardening](#-security-hardening)
- [Verification](#-verification)
- [Configuration Files](#-configuration-files)

---

## 🔍 Introduction

### What is Monitoring?
Monitoring is the systematic observation and recording of system metrics to ensure reliability, performance, and availability of services.

### Use Cases
- Performance tracking and optimization
- Incident detection and alerting
- Capacity planning and resource management
- SLA compliance verification
- Root cause analysis

---

## 📚 Core Concepts

### Types of Monitoring

**Blackbox Monitoring :**
External monitoring that tests services from the user's perspective without internal system knowledge.

**Whitebox Monitoring :**
Internal monitoring that uses system metrics and logs to understand service behavior.

### What are Metrics?
Numerical measurements collected over time that represent the state and performance of a system.

**Prometheus** = Time series metrics database optimized for monitoring and alerting.

### Metrics Collection Methods

| Type | Description |
|------|-------------|
| **Pull-Based** | Prometheus scrapes metrics from targets at configured intervals |
| **Push-Based** | Applications push metrics to a collector (Pushgateway) |

### What to Measure?

#### 🎯 The 4 Golden Signals (Google)
1. **Latency** - Time to service requests
2. **Traffic** - Demand on your system
3. **Errors** - Rate of failed requests
4. **Saturation** - Resource utilization

#### 🔧 USE Method (Brendan Gregg)
- **U**tilization - Resource busy time
- **S**aturation - Work queue length
- **E**rrors - Error events

#### 🔴 RED Method (Tom Wilkie)
- **R**ate - Requests per second
- **E**rrors - Failed requests rate
- **D**uration - Request latency

---

## 🏗️ Architecture

### Before Production Implementation

Ensure your organization has:
1. **Service Flow Diagram** - Understanding of service dependencies
2. **UML Diagrams** - System component relationships
3. **Network Topology** - Infrastructure layout and connections

### Prometheus Architecture Overview

<img width="1280" height="720" alt="image" src="https://github.com/user-attachments/assets/fb47e30e-8f1f-4c4a-bf47-9305d46a0a2c" />

---

## ⚙️ Prerequisites

- **OS**: Debian/Ubuntu or RedHat/CentOS
- **Packages**: `chrony`, `firewalld`, `jq`, `apache2-utils`/`httpd-tools`
- **Permissions**: Root or sudo access
- **Network**: Appropriate ports open (9090, 9100, 9115, 3000, 8080)
- **Optional**: Docker (for cAdvisor)

---

## 🚀 Installation & Configuration

### 1. Prometheus Server

**Default Port**: `9090`

#### Installation Steps (Debian)

```bash
# Update system and install dependencies
sudo apt update -y && sudo apt install -y chrony firewalld jq

# Download Prometheus
wget https://github.com/prometheus/prometheus/releases/download/v3.5.0/prometheus-3.5.0.linux-amd64.tar.gz
tar -xvf prometheus-3.5.0.linux-amd64.tar.gz

# Create user and directories
sudo useradd -rs /sbin/nologin prometheus
sudo mkdir -p /etc/prometheus /etc/prometheus/tls /var/lib/prometheus

# Set permissions
sudo chown prometheus. /etc/prometheus /etc/prometheus/tls /var/lib/prometheus
sudo chmod 700 /etc/prometheus /etc/prometheus/tls
sudo chmod 755 /var/lib/prometheus

# Install binaries
cd prometheus-3.5.0.linux-amd64
sudo mv prometheus promtool /usr/local/bin
sudo chown prometheus. /usr/local/bin/prom*

# Generate TLS certificates
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout prometheus.key -out prometheus.crt \
  -subj "/CN=prometheus.local"
sudo mv prometheus.crt prometheus.key /etc/prometheus/tls/
sudo chown prometheus. /etc/prometheus/tls/prometheus.{crt,key}
sudo chmod 644 /etc/prometheus/tls/prometheus.crt
sudo chmod 600 /etc/prometheus/tls/prometheus.key

# Configure basic authentication
sudo apt install apache2-utils
htpasswd -nBb admin abbaseboazar  # Generate password hash

# Create configuration files
sudo -u prometheus vim /etc/prometheus/prometheus.yml
sudo vim /etc/prometheus/web-config.yml  # if you want to set SSL/TLS, User/Pass for login you can add it to this file
sudo vim /usr/lib/systemd/system/prometheus.service

# Configure firewall
sudo firewall-cmd --add-port=9090/tcp --permanent
sudo firewall-cmd --reload

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable --now prometheus.service
```

#### Verification
```bash
sudo systemctl status prometheus.service
sudo ss -tunpla | grep 9090
```

#### Access
`https://localhost:9090` or `https://your-ip:9090`

---

### 2. Node Exporter

**Default Port**: `9100`

#### What is Node Exporter?
System metrics exporter for Unix-like systems (CPU, memory, disk, network).

**Note**: For Windows, use `WMI_exporter` or `windows_exporter`.

#### Installation Steps (Debian)

```bash
# Download Node Exporter
wget https://github.com/prometheus/node_exporter/releases/download/v1.10.2/node_exporter-1.10.2.linux-amd64.tar.gz
tar -xvf node_exporter-1.10.2.linux-amd64.tar.gz

# Create user
sudo useradd -rs /sbin/nologin exporter

# Install binary
cd node_exporter-1.10.2.linux-amd64
sudo mv node_exporter /usr/local/bin
sudo chown exporter. /usr/local/bin/node_exporter
sudo chmod 755 /usr/local/bin/node_exporter

# Create systemd service
sudo vim /usr/lib/systemd/system/node_exporter.service

# Configure firewall
sudo firewall-cmd --add-port=9100/tcp --permanent
sudo firewall-cmd --reload

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable --now node_exporter.service
```

#### Verification
```bash
sudo systemctl status node_exporter.service
sudo ss -tunpla | grep 9100
```

#### Access
`http://localhost:9100/metrics` or `http://your-ip:9100/metrics`

---

### 3. Blackbox Exporter

**Default Port**: `9115`

#### What is Blackbox Exporter?
Probe-based exporter for external monitoring (HTTP, TCP, ICMP, DNS).

#### Installation Steps (Debian)

```bash
# Download Blackbox Exporter
wget https://github.com/prometheus/blackbox_exporter/releases/download/v0.27.0/blackbox_exporter-0.27.0.linux-amd64.tar.gz
tar -xvf blackbox_exporter-0.27.0.linux-amd64.tar.gz

# Install binary and configuration
cd blackbox_exporter-0.27.0.linux-amd64
sudo mv blackbox_exporter /usr/local/bin
sudo chown exporter. /usr/local/bin/blackbox_exporter
sudo chmod 755 /usr/local/bin/blackbox_exporter

sudo mv blackbox.yml /etc/prometheus
sudo vim /etc/prometheus/blackbox.yml

# Create systemd service
sudo cp /usr/lib/systemd/system/{node,blackbox}_exporter.service
sudo vim /usr/lib/systemd/system/blackbox_exporter.service

# Configure firewall
sudo firewall-cmd --add-port=9115/tcp --permanent
sudo firewall-cmd --reload

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable --now blackbox_exporter.service
```

#### Enable Remote ICMP Probing (if needed)

```bash
# Check current setting
sudo sysctl -a | grep ping
# Output: net.ipv4.ping_group_range=1 0

# Allow unprivileged ICMP
sudo vim /etc/sysctl.conf
# Add: net.ipv4.ping_group_range=0 2147483647
sudo sysctl -p
```

#### URL Components Reference
```
schema://[subdomain].domain.tld[:Port]/file_path[?param1=value1[&param2=value2]]
```

#### Example Probes
```bash
# ICMP probe
http://127.0.0.1:9115/probe?module=icmp&target=localhost

# HTTP probe
http://127.0.0.1:9115/probe?module=http_2xx&target=https://example.com
```

**Result Interpretation**:
- `probe_success 1` → ✅ Success
- `probe_success 0` → ❌ Failure

#### Verification
```bash
sudo systemctl status blackbox_exporter.service
sudo ss -tunpla | grep 9115
```

#### Access
`http://localhost:9115` or `http://your-ip:9115`

---

### 4. cAdvisor

**Default Port**: `8080`

#### What is cAdvisor?
Container metrics exporter for Docker and Kubernetes environments.

#### Installation Steps (Docker)

```bash
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
# or we can use google/cadvisor:canary image
```

#### Verification
```bash
docker ps | grep cadvisor
curl http://localhost:8080/metrics
```

#### Access
`http://localhost:8080` or `http://your-ip:8080`

---

### 5. Grafana

**Default Port**: `3000`

#### What is Grafana?
Data visualization and analytics platform that queries metrics and renders beautiful dashboards.

**Workflow**: Metrics → Query → Visualization

#### Installation Steps (Debian)

```bash
# Install dependencies
sudo apt update -y && sudo apt install -y libfontconfig1 musl

# Download and install Grafana
wget https://dl.grafana.com/grafana-enterprise/release/12.2.1/grafana-enterprise_12.2.1_18655849634_linux_amd64.deb
sudo dpkg -i grafana-enterprise_12.2.1_18655849634_linux_amd64.deb

# Create TLS directory and certificates
sudo mkdir -p /etc/grafana/tls
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout grafana.key -out grafana.crt \
  -subj "/CN=grafana.local"
sudo mv grafana.{crt,key} /etc/grafana/tls/

# Set permissions
sudo chown grafana. /etc/grafana/tls /etc/grafana/tls/*
sudo chmod 700 /etc/grafana/tls
sudo chmod 644 /etc/grafana/tls/grafana.crt
sudo chmod 600 /etc/grafana/tls/grafana.key

# Configure Grafana
sudo vim /etc/grafana/grafana.ini  # if you want to set SSL/TLS for login you can add it to this file
sudo vim /usr/lib/systemd/system/grafana-server.service

# Configure firewall
sudo firewall-cmd --add-port=3000/tcp --permanent
sudo firewall-cmd --reload

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable --now grafana-server.service
```

#### Installation Steps (RedHat)

```bash
sudo yum install -y https://dl.grafana.com/grafana-enterprise/release/12.2.1/grafana-enterprise_12.2.1_18655849634_linux_amd64.rpm
```

#### Verification
```bash
sudo systemctl status grafana-server.service
sudo ss -tunpla | grep 3000
```

#### Access
`https://localhost:3000` or `https://your-ip:3000`

**Default Credentials**: `admin` / (configured in grafana.ini)

---

## 🔒 Security Hardening

### TLS/SSL Configuration
- ✅ All services configured with TLS certificates
- ✅ Self-signed certificates for internal networks
- ✅ Proper file permissions (600 for keys, 644 for certs)

### Authentication
- ✅ prometheus: Basic auth with bcrypt hashed passwords
- ✅ grafana: Custom admin credentials
- ✅ Restricted user privileges (dedicated service accounts)

### Firewall Rules
```bash
# Prometheus
sudo firewall-cmd --add-port=9090/tcp --permanent

# Node Exporter
sudo firewall-cmd --add-port=9100/tcp --permanent

# Blackbox Exporter
sudo firewall-cmd --add-port=9115/tcp --permanent

# Grafana
sudo firewall-cmd --add-port=3000/tcp --permanent

# Apply changes
sudo firewall-cmd --reload
```

### File Permissions
```bash
# Configuration directories
sudo chmod 700 /etc/prometheus
sudo chmod 700 /etc/prometheus/tls
sudo chmod 700 /etc/grafana/tls

# Certificate files
sudo chmod 644 /etc/prometheus/tls/*.crt
sudo chmod 600 /etc/prometheus/tls/*.key
sudo chmod 644 /etc/grafana/tls/*.crt
sudo chmod 600 /etc/grafana/tls/*.key

# Data directories
sudo chmod 755 /var/lib/prometheus
```

### Systemd Service Hardening
- Dedicated non-root users (`prometheus`, `exporter`, `grafana`)
- Locked down service capabilities
- No shell access (`/sbin/nologin`)
- Proper working directories and runtime permissions

---

## ✅ Verification

### Check Service Status
```bash
# All services
sudo systemctl status prometheus.service
sudo systemctl status node_exporter.service
sudo systemctl status blackbox_exporter.service
sudo systemctl status grafana-server.service

# Docker container
docker ps | grep cadvisor
```

### Check Network Ports
```bash
sudo ss -tunpla | grep -E '(9090|9100|9115|3000|8080)'
```

### Test Endpoints
```bash
# Prometheus
curl -k -u admin:abbaseboazar https://localhost:9090/-/healthy

# Node Exporter
curl http://localhost:9100/metrics

# Blackbox Exporter
curl http://localhost:9115/probe?module=icmp_v4&target=localhost

# cAdvisor
curl http://localhost:8080/metrics

# Grafana
curl -k https://localhost:3000/api/health
```

---

## 📄 Configuration Files

### Required Configuration Files

| File | Location | Purpose |
|------|----------|---------|
| `prometheus.yml` | `/etc/prometheus/` | Main Prometheus configuration |
| `web-config.yml` | `/etc/prometheus/` | TLS and authentication settings |
| `blackbox.yml` | `/etc/prometheus/` | Blackbox probe configurations |
| `grafana.ini` | `/etc/grafana/` | Grafana server settings |
| `prometheus.service` | `/usr/lib/systemd/system/` | Prometheus systemd unit |
| `node_exporter.service` | `/usr/lib/systemd/system/` | Node Exporter systemd unit |
| `blackbox_exporter.service` | `/usr/lib/systemd/system/` | Blackbox Exporter systemd unit |
| `grafana-server.service` | `/usr/lib/systemd/system/` | Grafana systemd unit |

**Note**: Configuration file templates are included in this repository.

---

## 💡 Pro Tips

### Systemd Service Files
- Unit files (service files) can be stored in three places (in order)

|             RH            |         DEB         |
|---------------------------|---------------------|
| /etc/systemd/system       | /etc/systemd/system |
| /run/systemd/system       | /run/systemd/system |
| /usr/lib/systemd/system   | /lib/systemd/system |

- **Recommended Path**: `/usr/lib/systemd/system/`
- **Why?**: Using `systemctl mask` on services in `/etc/systemd/system/` can cause issues when unmounting (deletes the service file)

### Lock Files
- Prometheus creates lock files in `/var/lib/prometheus` to prevent multiple instances
- Automatically removed when service stops
- Use `--storage.agent.no-lockfile` to disable (not recommended)

### Console Libraries (Deprecated)
- Older Prometheus versions included `console_templates` and `console_libraries`
- Removed in favor of Grafana for visualization
- Simplified project maintenance

### URL Testing
Always include the `target` parameter when testing Blackbox exporter.
```bash
# ❌ Wrong
http://127.0.0.1:9115/probe

# ✅ Correct
http://127.0.0.1:9115/probe?module=icmp&target=localhost
```

---

## 📊 Example Scrape Configurations

### Multi-Job Setup
```yaml
scrape_configs:
  - job_name: 'Prometheus Server'
    static_configs:
      - targets: ['localhost:9090']
  
  - job_name: 'Node Exporter - Local'
    static_configs:
      - targets: ['localhost:9100']
  
  - job_name: 'Node Exporter - Remote'
    static_configs:
      - targets: ['192.168.56.111:9100']
  
  - job_name: 'Blackbox - ICMP Probes'
    metrics_path: /probe
    params:
      module: [icmp_v4]
    static_configs:
      - targets:
          - 4.2.2.4
          - www.example.com
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__address__]
        target_label: instance
      - target_label: __address__
        replacement: 127.0.0.1:9115
  
  - job_name: 'cAdvisor'
    static_configs:
      - targets: ['172.16.52.40:8080']
```


---

## 📞 Support

For issues and questions:
- Check Prometheus documentation: https://prometheus.io/docs
- Check Grafana documentation: https://grafana.com/docs

---

<div align="center">
  <sub>Created by Elyasdj</sub>
</div>
<div align="center">
  <sub>Guided by Mahdi Sardari</sub>
</div>

