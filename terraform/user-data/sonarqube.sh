#!/bin/bash
set -e

apt update -y
apt install -y docker.io docker-compose-v2

systemctl enable docker
systemctl start docker

mkdir -p /opt/sonarqube
cd /opt/sonarqube

cat > docker-compose.yml <<EOF
services:
  sonarqube:
    image: sonarqube:lts-community
    container_name: sonarqube
    ports:
      - "9000:9000"
    environment:
      SONAR_ES_BOOTSTRAP_CHECKS_DISABLE: "true"
    volumes:
      - sonarqube_data:/opt/sonarqube/data
      - sonarqube_logs:/opt/sonarqube/logs
      - sonarqube_extensions:/opt/sonarqube/extensions

volumes:
  sonarqube_data:
  sonarqube_logs:
  sonarqube_extensions:
EOF

echo "Starting SonarQube container..."
docker compose up -d || {
  echo "Failed to start SonarQube container"
  exit 1
}

echo "Waiting for SonarQube to be ready..."
sleep 10

echo "SonarQube setup completed successfully"