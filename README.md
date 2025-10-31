<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Production Monitoring Stack with Prometheus & Grafana</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
            line-height: 1.6;
            background-color: #f6f8fa;
            color: #24292e;
            max-width: 980px;
            margin: 20px auto;
            padding: 20px;
        }
        h1, h2, h3 {
            border-bottom: 2px solid #eaecef;
            padding-bottom: .3em;
            margin-top: 24px;
            margin-bottom: 16px;
            font-weight: 600;
        }
        h1 { font-size: 2.5em; }
        h2 { font-size: 2em; }
        h3 { font-size: 1.5em; }
        pre {
            background-color: #ffffff;
            border: 1px solid #dfe2e5;
            border-radius: 6px;
            padding: 16px;
            overflow: auto;
            line-height: 1.45;
        }
        code {
            font-family: "SFMono-Regular", Consolas, "Liberation Mono", Menlo, Courier, monospace;
            font-size: 85%;
            background-color: rgba(27,31,35,.05);
            border-radius: 3px;
            padding: .2em .4em;
        }
        pre > code {
            font-size: 100%;
            background-color: transparent;
            border: 0;
            padding: 0;
        }
        ul, ol {
            padding-left: 2em;
        }
        li {
            margin-bottom: 8px;
        }
        hr {
            height: .25em;
            padding: 0;
            margin: 24px 0;
            background-color: #e1e4e8;
            border: 0;
        }
    </style>
</head>
<body>

    <h1>Production Monitoring Stack with Prometheus & Grafana</h1>

    <p>This repository contains the configuration files and step-by-step instructions for deploying a robust, production-ready monitoring stack using Prometheus, Grafana, and various exporters.</p>

    <hr>

    <h2>1. Core Monitoring Concepts</h2>

    <h3>What is Monitoring?</h3>
    <p>Monitoring is the process of collecting, processing, and displaying real-time data about a system's health and performance.</p>

    <h3>Use Cases</h3>
    <ul>
        <li>Alerting and Debugging</li>
        <li>Performance Analysis</li>
        <li>Capacity Planning</li>
        <li>System Observability</li>
    </ul>

    <h3>Types of Monitoring</h3>
    <ul>
        <li><strong>Blackbox:</strong> Probing a system from the outside to test user-facing behavior (e.g., "Is the website up?").</li>
        <li><strong>Whitebox:</strong> Monitoring a system from the inside using internal metrics and logs (e.g., "What is the CPU usage?").</li>
    </ul>

    <h3>What are Metrics?</h3>
    <p>A metric is a numerical measurement of a system's property over time. Prometheus uses a <strong>time-series</strong> model for metrics.</p>

    <h3>Types of Metric Collection</h3>
    <ul>
        <li><strong>Pull-based:</strong> The monitoring server (Prometheus) periodically scrapes (pulls) metrics from target endpoints.</li>
        <li><strong>Push-based:</strong> Target services actively push their metrics to a central gateway.</li>
    </ul>

    <hr>

    <h2>2. Monitoring Strategy</h2>

    <h3>What to Measure?</h3>
    <p>Three popular methodologies for identifying key metrics:</p>
    <ul>
        <li><strong>RED Method (Tom Wilkie):</strong> For microservices.
            <ul>
                <li><strong>R</strong>ate: The number of requests per second.</li>
                <li><strong>E</strong>rrors: The number of failing requests.</li>
                <li><strong>D</strong>uration: The amount of time requests take.</li>
            </ul>
        </li>
        <li><strong>USE Method (Brendan Gregg):</strong> For system resources.
            <ul>
                <li><strong>U</strong>tilization: How busy the resource is.</li>
                <li><strong>S</strong>aturation: The degree to which the resource has excess work queued.</li>
                <li><strong>E</strong>rrors: The count of error events.</li>
            </ul>
        </li>
        <li><strong>The Four Golden Signals (Google SRE):</strong>
            <ul>
                <li><strong>Latency:</strong> The time it takes to service a request.</li>
                <li><strong>Traffic:</strong> A measure of demand on the system.</li>
                <li><strong>Errors:</strong> The rate of requests that fail.</li>
                <li><strong>Saturation:</strong> How "full" your service is.</li>
            </ul>
        </li>
    </ul>

    <h3>Prerequisites for Implementation</h3>
    <p>Before implementing monitoring in production, the business should have:</p>
    <ol>
        <li>A clear <strong>Service Flow</strong> diagram.</li>
        <li>A <strong>UMT (User-Machine-Task) Diagram</strong>.</li>
        <li>A detailed <strong>Network Diagram</strong>.</li>
    </ol>

    <hr>

    <h2>3. Stack Architecture</h2>
    
    <p></p>

    <p>This stack includes the following components:</p>
    <ul>
        <li><strong>Prometheus Server:</strong> The core time-series database and scraping engine.</li>
        <li><strong>Node Exporter:</strong> Gathers hardware and OS metrics from Unix-like hosts. (Use <strong>WMI Exporter</strong> for Windows).</li>
        <li><strong>Blackbox Exporter:</strong> Probes endpoints over <code>http</code>, <code>tcp</code>, <code>icmp</code>, and <code>dns</code> for blackbox monitoring.</li>
        <li><strong>cAdvisor:</strong> Collects, processes, and exports resource usage and performance data for running containers.</li>
        <li><strong>Grafana:</strong> The visualization platform for querying and displaying metrics in dashboards.</li>
    </ul>

    <hr>

    <h2>4. Installation & Configuration</h2>

    <p>All installation steps below are for <strong>Debian</strong> using <strong>binary files</strong>, unless otherwise noted.</p>

    <h3>1. Prometheus Server</h3>
    <ul>
        <li><strong>Default Port:</strong> <code>9090</code></li>
    </ul>

    <strong>Installation (Binary - Debian):</strong>
<pre><code># Install dependencies
sudo apt update -y && sudo apt install -y chrony firewalld jq 

# Download and extract
wget https://github.com/prometheus/prometheus/releases/download/v3.5.0/prometheus-3.5.0.linux-amd64.tar.gz
tar -xvf prometheus-3.5.0.linux-amd64.tar.gz

# Create user and directories
sudo useradd -s -r /sbin/nologin prometheus
sudo mkdir /etc/prometheus && sudo mkdir /etc/prometheus/tls 
sudo mkdir /var/lib/prometheus
sudo chown prometheus. /etc/prometheus /etc/prometheus/tls /var/lib/prometheus
sudo chmod 700 /etc/prometheus /etc/prometheus/tls
sudo chmod 755 /var/lib/prometheus

# Move binaries
cd prometheus-3.5.0.linux-amd64
sudo mv prometheus promtool /usr/local/bin
sudo chown prometheus. /usr/local/bin/prom*
</code></pre>

    <strong>Hardening (TLS & Basic Auth):</strong>
<pre><code># Open firewall port
sudo firewall-cmd --add-port=9090/tcp --permanent && sudo firewall-cmd --reload

# Generate self-signed TLS certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout prometheus.key -out prometheus.crt -subj "/CN=prometheus.local"
sudo mv prometheus.crt prometheus.key /etc/prometheus/tls/
sudo chown prometheus. /etc/prometheus/tls/prometheus.crt 
sudo chown prometheus. /etc/prometheus/tls/prometheus.key
sudo chmod 644 /etc/prometheus/tls/prometheus.crt
sudo chmod 600 /etc/prometheus/tls/prometheus.key

# Create web-config file
sudo touch /etc/prometheus/web-config.yml

# Install apache2-utils and generate a htpasswd hash
sudo apt install apache2-utils
htpasswd -n -B -b admin abbaseboazar 
# (Add the generated hash to web-config.yml)
</code></pre>

    <strong>Service Management:</strong>
    <ul>
        <li>Place <code>prometheus.service</code> in <code>/usr/lib/systemd/system/</code>.</li>
        <li>Place <code>prometheus.yml</code> in <code>/etc/prometheus/</code>.</li>
        <li>Place <code>web-config.yml</code> in <code>/etc/prometheus/</code>.</li>
    </ul>
<pre><code>sudo systemctl daemon-reload
sudo systemctl enable --now prometheus.service
</code></pre>

    <hr>

    <h3>2. Node Exporter</h3>
    <ul>
        <li><strong>Default Port:</strong> <code>9100</code></li>
        <li><strong>Collects:</strong> Unix-like system metrics (CPU, memory, disk, network).</li>
    </ul>

    <strong>Installation (Binary - Debian):</strong>
<pre><code>wget https://github.com/prometheus/node_exporter/releases/download/v1.10.2/node_exporter-1.10.2.linux-amd64.tar.gz
tar -xvf node_exporter-1.10.2.linux-amd64.tar.gz

# Create exporter user
sudo useradd -s -r /sbin/nologin exporter

# Move binary
cd node_exporter-1.10.2.linux-amd64
sudo mv node_exporter /usr/local/bin
sudo chown exporter. /usr/local/bin/node_exporter
sudo chmod 755 /usr/local/bin/node_exporter
</code></pre>

    <strong>Hardening:</strong>
<pre><code>sudo firewall-cmd --add-port=9100/tcp --permanent && sudo firewall-cmd --reload
</code></pre>

    <strong>Service Management:</strong>
    <ul>
        <li>Place <code>node_exporter.service</code> in <code>/usr/lib/systemd/system/</code>.</li>
    </ul>
<pre><code>sudo systemctl daemon-reload
sudo systemctl enable --now node_exporter.service
</code></pre>

    <hr>

    <h3>3. Blackbox Exporter</h3>
    <ul>
        <li><strong>Default Port:</strong> <code>9115</code></li>
        <li><strong>Probes:</strong> <code>http</code>, <code>tcp</code>, <code>icmp</code>, <code>dns</code>.</li>
    </ul>

    <strong>Installation (Binary - Debian):</strong>
<pre><code>wget https://github.com/prometheus/blackbox_exporter/releases/download/v0.27.0/blackbox_exporter-0.27.0.linux-amd64.tar.gz
tar -xvf blackbox_exporter-0.27.0.linux-amd64.tar.gz
cd blackbox_exporter-0.27.0.linux-amd64

# Move binary and config
sudo mv blackbox_exporter /usr/local/bin
sudo chown exporter. /usr/local/bin/blackbox_exporter
sudo chmod 755 /usr/local/bin/blackbox_exporter
sudo mv blackbox.yml /etc/prometheus
</code></pre>

    <strong>Hardening:</strong>
<pre><code>sudo firewall-cmd --add-port=9115/tcp --permanent
sudo firewall-cmd --reload
</code></pre>

    <strong>Service Management:</strong>
    <ul>
        <li>Place <code>blackbox_exporter.service</code> in <code>/usr/lib/systemd/system/</code>.</li>
        <li>Place <code>blackbox.yml</code> in <code>/etc/prometheus/</code>.</li>
    </ul>
<pre><code>sudo systemctl daemon-reload
sudo systemctl enable --now blackbox_exporter.service
</code></pre>

    <hr>

    <h3>4. cAdvisor</h3>
    <ul>
        <li><strong>Default Port:</strong> <code>8080</code></li>
    </ul>

    <strong>Installation (Docker):</strong>
<pre><code>docker run -itd \
  --volume=/:/rootfs:ro \
  --volume=/var/run:/var/run:ro \
  --volume=/sys:/sys:ro \
  --volume=/var/lib/docker/:/var/lib/docker:ro \
  --volume=/dev/disk/:/dev/disk:ro \
  --publish=8080:8080 \
  --name=cadvisor \
  --privileged \
  --device=/dev/kmsg \
  --network mynetwork \
  --restart always \
  ghcr.io/google/cadvisor:v0.53.0
</code></pre>

    <hr>

    <h3>5. Grafana</h3>
    <ul>
        <li><strong>Default Port:</strong> <code>3000</code></li>
        <li><strong>Function:</strong> Metrics -> Query -> Visualization</li>
    </ul>

    <strong>Installation (Package Manager - Debian):</strong>
<pre><code>sudo apt update -y && sudo apt install -y libfontconfig1 musl
wget https://dl.grafana.com/grafana-enterprise/release/12.2.1/grafana-enterprise_12.2.1_18655849634_linux_amd64.deb
sudo dpkg -i grafana-enterprise_12.2.1_18655849634_linux_amd64.deb
</code></pre>

    <strong>Installation (Package Manager - RedHat):</strong>
<pre><code>sudo yum install -y https://dl.grafana.com/grafana-enterprise/release/12.2.1/grafana-enterprise_12.2.1_18655849634_linux_amd64.rpm
</code></pre>

    <strong>Hardening (TLS):</strong>
<pre><code>sudo mkdir -p /etc/grafana/tls

# Generate self-signed TLS certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout grafana.key -out grafana.crt -subj "/CN=grafana.local"
sudo cp grafana.{crt,key} /etc/grafana/tls/

# Set permissions
sudo chown grafana. /etc/grafana/tls /etc/grafana/tls/*
sudo chmod 700 /etc/grafana/tls
sudo chmod 644 /etc/grafana/tls/grafana.crt
sudo chmod 600 /etc/grafana/tls/grafana.key

# Open firewall port
sudo firewall-cmd --add-port=3000/tcp --permanent
sudo firewall-cmd --reload
</code></pre>

    <strong>Service Management:</strong>
    <ul>
        <li>Edit <code>grafana.ini</code> at <code>/etc/grafana/grafana.ini</code> to enable HTTPS and set admin credentials.</li>
        <li>The <code>grafana-server.service</code> file is managed by the package.</li>
    </ul>
<pre><code>sudo systemctl daemon-reload
sudo systemctl enable --now grafana-server.service
</code></pre>

    <hr>

    <h2>5. Configuration Files</h2>

    <p>This repository includes the following configuration files:</p>
    <ul>
        <li><code>/etc/prometheus/prometheus.yml</code>: Main Prometheus config, defines scrape jobs.</li>
        <li><code>/etc/prometheus/web-config.yml</code>: Configures TLS and Basic Auth for the Prometheus UI.</li>
        <li><code>/etc/prometheus/blackbox.yml</code>: Defines probe modules for Blackbox Exporter.</li>
        <li><code>/etc/grafana/grafana.ini</code>: Main Grafana configuration (set up HTTPS, admin user, etc.).</li>
        <li><code>/usr/lib/systemd/system/prometheus.service</code>: Systemd service file for Prometheus.</li>
        <li><code>/usr/lib/systemd/system/node_exporter.service</code>: Systemd service file for Node Exporter.</li>
        <li><code>/usr/lib/systemd/system/blackbox_exporter.service</code>: Systemd service file for Blackbox Exporter.</li>
        <li><code>/usr/lib/systemd/system/grafana-server.service</code>: Systemd service file for Grafana.</li>
    </ul>

    <hr>

    <h2>6. Key Tips & Troubleshooting</h2>

    <h3>✅ Always Check Service Status</h3>
    <p>After starting any service, always check its status and listening ports:</p>
<pre><code>sudo systemctl status &lt;service_name.service&gt;
sudo ss -tunpla
</code></pre>

    <h3>🖥️ Accessing Web Panels (with HTTPS enabled)</h3>
    <ul>
        <li><strong>Prometheus:</strong> <code>https://&lt;your-ip&gt;:9090</code></li>
        <li><strong>Grafana:</strong> <code>https://&lt;your-ip&gt;:3000</code></li>
        <li><strong>cAdvisor:</strong> <code>http://&lt;your-ip&gt;:8080</code></li>
        <li><strong>Node Exporter Metrics:</strong> <code>http://&lt;your-ip&gt;:9100/metrics</code></li>
        <li><strong>Blackbox Exporter:</strong> <code>http://&lt;your-ip&gt;:9115</code></li>
    </ul>

    <h3>💡 Systemd Service File Path</h3>
    <p>Systemd unit files are loaded in this order:</p>
    <ol>
        <li><code>/etc/systemd/system</code></li>
        <li><code>/run/systemd/system</code></li>
        <li><code>/usr/lib/systemd/system</code></li>
    </ol>
    <p><strong>Recommendation:</strong> Use <code>/usr/lib/systemd/system</code>. If you <code>mask</code> and then <code>unmask</code> a service, the symlink in <code>/etc/systemd/system</code> is deleted, which can cause issues. Placing the file in <code>/usr/lib</code> is more resilient.</p>

    <h3>💡 Prometheus Lockfile</h3>
    <p>Prometheus creates a <code>lock</code> file in <code>/var/lib/prometheus</code> to prevent multiple instances from accessing the data directory. This file is automatically deleted on a clean <code>systemctl stop</code>. You can disable this with the <code>--storage.agent.no-lockfile</code> flag.</p>

    <h3>💡 Missing Console Libraries in Prometheus</h3>
    <p>Newer Prometheus versions no longer include the <code>console</code> and <code>console_library</code> directories. These were for old HTML/CSS-based dashboards, which are now obsolete. The focus is on using Grafana for all visualization.</p>

    <h3>💡 Blackbox ICMP (Ping) Troubleshooting</h3>
    <p>On some distributions, the <code>exporter</code> user cannot send ICMP packets.</p>
    <ul>
        <li><strong>Symptom:</strong> <code>probe_success 0</code> for ICMP modules.</li>
        <li><strong>Solution:</strong> Allow unprivileged users to send pings.</li>
    </ul>
<pre><code># Check current setting
sudo sysctl -a | grep ping_group_range
    
# Add the following line to /etc/sysctl.conf and run 'sudo sysctl -p'
net.ipv4.ping_group_range=0 21474483647
</code></pre>

    <h3>💡 Using the Blackbox Exporter</h3>
    <p>To probe a target, you must call the <code>/probe</code> endpoint with <code>module</code> and <code>target</code> parameters:</p>
<pre><code># Example:
http://127.0.0.1:9115/probe?module=icmp&target=google.com
</code></pre>
    <ul>
        <li>Look for the metric <code>probe_success 1</code> (OK) or <code>probe_success 0</code> (NOK).</li>
    </ul>

</body>
</html>
