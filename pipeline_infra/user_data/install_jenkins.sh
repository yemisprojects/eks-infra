#!/bin/bash
################################################################################
# JENKINS INSTALLATION 
################################################################################
apt update && apt install openjdk-11-jdk -y
wget -O /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
apt-get update
sudo apt-get install jenkins -y
systemctl enable jenkins && systemctl start jenkins

################################################################################
# INSTALL maven
################################################################################
apt install maven -y

################################################################################
# INSTALL DOCKER
################################################################################
apt-get update
apt-get install docker.io -y
usermod -aG docker jenkins 
chmod 660 /var/run/docker.sock

################################################################################
# INSTALL TRIVY
################################################################################
apt-get install wget apt-transport-https gnupg lsb-release -y
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | tee /usr/share/keyrings/trivy.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | tee -a /etc/apt/sources.list.d/trivy.list
apt-get update
apt-get install trivy -y

################################################################################
# INSTALL aws cli
################################################################################
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
apt-get install unzip -y
unzip awscliv2.zip
./aws/install
