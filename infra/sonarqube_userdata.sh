#!/bin/bash
set -x
exec > /var/log/sonarqube-install.log 2>&1

# 1. Kernel settings
echo "vm.max_map_count=524288" >> /etc/sysctl.conf
echo "fs.file-max=131072" >> /etc/sysctl.conf
sysctl -p

# 2. Java 21 + tools
apt-get update -y
apt-get install -y openjdk-21-jdk unzip postgresql postgresql-contrib

# 3. PostgreSQL database
systemctl enable --now postgresql
sudo -i -u postgres psql -c "CREATE USER sonar WITH ENCRYPTED PASSWORD 'admin123';"
sudo -i -u postgres psql -c "CREATE DATABASE sonarqube OWNER sonar;"

# 4. SonarQube
cd /tmp
curl -sSLO https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-26.4.0.121862.zip
unzip -o sonarqube-26.4.0.121862.zip -d /opt/
mv /opt/sonarqube-26.4.0.121862 /opt/sonarqube

# 5. Service user (one name everywhere)
useradd -r -m -d /opt/sonarqube -s /bin/bash sonarqube
chown -R sonarqube:sonarqube /opt/sonarqube

# 6. Database connection
cat >> /opt/sonarqube/conf/sonar.properties << 'EOF'
sonar.jdbc.username=sonar
sonar.jdbc.password=admin123
sonar.jdbc.url=jdbc:postgresql://localhost:5432/sonarqube
EOF

# 7. systemd unit
cat > /etc/systemd/system/sonarqube.service << 'EOF'
[Unit]
Description=SonarQube service
After=network.target postgresql.service

[Service]
Type=forking
ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop
User=sonarqube
Group=sonarqube
Restart=on-failure
LimitNOFILE=131072
LimitNPROC=8192

[Install]
WantedBy=multi-user.target
EOF

# 8. Launch
systemctl daemon-reload
systemctl enable --now sonarqube
