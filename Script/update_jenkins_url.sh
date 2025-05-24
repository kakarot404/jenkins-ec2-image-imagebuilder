#!/bin/bash
              
sleep 10
              
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

PUBLIC_IP=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/public-ipv4)
              
if [ -z "$PUBLIC_IP" ]; then
    echo "Error: Unable to fetch public IP. Exiting..."
    exit 1
fi
              
echo "The current public IP is: $PUBLIC_IP"
              
JENKINS_CONFIG_FILE="/var/lib/jenkins/jenkins.model.JenkinsLocationConfiguration.xml"

if [ -f "$JENKINS_CONFIG_FILE" ]; then
    sudo sed -i "s|<jenkinsUrl>http://.*:8080/</jenkinsUrl>|<jenkinsUrl>http://$PUBLIC_IP:8080/</jenkinsUrl>|g" "$JENKINS_CONFIG_FILE"
    sudo systemctl restart jenkins
else
    echo "Jenkins config file not found. Skipping URL update."
fi

sudo cp /var/log/jenkins_url_update.log /var/log/amazon/imagebuilder/jenkins_url_update.log