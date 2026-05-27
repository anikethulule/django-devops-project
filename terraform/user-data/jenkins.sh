#!/bin/bash
set -e

apt update -y
apt install -y openjdk-21-jdk curl wget git unzip docker.io awscli

systemctl enable docker
systemctl start docker
usermod -aG docker ubuntu

# Add Jenkins repository (2026 key from pkg.origin.jenkins.io)
echo "Adding Jenkins repository..."
curl -fsSL https://pkg.origin.jenkins.io/debian-stable/jenkins.io-2026.key | tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.origin.jenkins.io/debian-stable/ binary/" | tee /etc/apt/sources.list.d/jenkins.list > /dev/null

apt update -y || true

# Install Jenkins with retries
for i in {1..3}; do
  echo "Jenkins installation attempt $i..."
  if apt install -y jenkins 2>/dev/null; then
    echo "Jenkins installed successfully"
    break
  fi
  if [ $i -lt 3 ]; then
    echo "Installation failed, retrying in 5 seconds..."
    sleep 5
  fi
done

systemctl enable jenkins
systemctl start jenkins

# Allow Jenkins to run Docker commands, then reload service
usermod -aG docker jenkins
systemctl restart docker
systemctl restart jenkins

# Download and install kubectl
echo "Installing kubectl..."
cd /tmp
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client
cd /

# Install trivy via apt repository
echo "Installing trivy..."
apt-get install -y wget gnupg lsb-release
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | apt-key add -
echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | tee -a /etc/apt/sources.list.d/trivy.list
apt-get update
apt-get install -y trivy

echo "Jenkins setup completed successfully"