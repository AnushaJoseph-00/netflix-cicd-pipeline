#!/bin/bash
set -x
exec > /var/log/nexus-install.log 2>&1

# Java 17 (Nexus runs on it)
apt-get update -y
apt-get install -y openjdk-17-jdk

# Download and extract Nexus 3
cd /tmp
wget -q https://download.sonatype.com/nexus/3/latest-unix.tar.gz
tar -xzf latest-unix.tar.gz -C /opt/
mv /opt/nexus-3* /opt/nexus

# Service user + ownership
useradd -r -m -d /opt/nexus -s /bin/bash nexus
chown -R nexus:nexus /opt/nexus /opt/sonatype-work
echo 'run_as_user="nexus"' > /opt/nexus/bin/nexus.rc

# systemd unit
cat > /etc/systemd/system/nexus.service << 'EOF'
[Unit]
Description=Nexus Repository
After=network.target

[Service]
Type=forking
ExecStart=/opt/nexus/bin/nexus start
ExecStop=/opt/nexus/bin/nexus stop
User=nexus
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now nexus
