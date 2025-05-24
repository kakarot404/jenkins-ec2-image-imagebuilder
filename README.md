# 🔧 AWS Image Builder – Jenkins Preinstalled (Ubuntu)

This project automates the creation of an AWS AMI with Jenkins pre-installed and configured using **AWS EC2 Image Builder**. It leverages a modular pipeline with clearly defined build and test components, validated through scripting and cron-based checks.

---
## File Structure:

```graphql
jenkins-imagebuilder/
├── README.md
├── sample-logs / example-logs-cloudwatch.logs              #logs
├── components/                                             #Components for reference
│   ├── build-jenkins-component.yml
│   └── validate-jenkins-component.yml
└── scripts/                                                #Jenkins location URL update custom script 
    └── update_jenkins_url.sh
```
---
## 📦 Components Used

### 1️⃣ Build Component

- Adds the Jenkins GPG key and repository using:
```bash
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key

echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" \
| sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
```
- ⚠️ *Note:* The following approach caused issues and was avoided:
```bash
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
```
- Updates packages: `sudo apt-get update`
- Installs dependencies: `fontconfig`, `openjdk-17-jre`, `jenkins`

- Enables and starts Jenkins:
```bash
sudo systemctl enable jenkins
sudo systemctl start jenkins
```
- Adds a script: `/usr/local/bin/update_jenkins_url.sh`
- Configures a cron job via `/etc/crontab` to run the script on reboot and log to:
`/var/log/jenkins_url_update.log`

### 2️⃣ Test Component:
Verified:

    Jenkins binary

    Jenkins service status

    Cron job presence

    Presence of URL updater script

---

## 🧱 Image Recipe

- Base OS: Ubuntu Server 20 LTS (later switched to 22 LTS)
- Architecture: `x86_64`
- Working directory: `/tmp`

---

### ⚙️ Infrastructure Configuration

- Instance Type: `m5.large` (can be changed as needed)
- IAM Role: `AWS-ec2ImageBuilderRole`
  - Policies attached:
    - `AmazonS3FullAccess`
    - `AmazonSSMManagedInstanceCore`
    - `EC2InstanceProfileForImageBuilder`
  - Trusted relationship:
    ```json
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Principal": {
            "Service": "ec2.amazonaws.com"
          },
          "Action": "sts:AssumeRole"
        }
      ]
    }
    ```
- Logging: Enabled
  - S3 bucket: `logs-general`
- Networking:
  - VPC
  - Subnet
  - Security Group
  - EC2 Key Pair
- `TerminateInstanceOnFailure`: **false** (for debug visibility)

---

### Image Pipeline

- Tied components + recipe + infra into a pipeline

- Used default workflow for simplicity

- Observed logs in S3 + CloudWatch

---
### Examplery Logs:

```graphql

2025-03-24T02:08:37.741+05:30
Image transitioned to DISTRIBUTING state for Image ARN: arn:aws:imagebuilder:us-east-1:123456789:image/jenkins-preset-recipe/0.0.2/2

2025-03-24T02:08:44.739+05:30
Image transitioned to INTEGRATING state for Image ARN: arn:aws:imagebuilder:us-east-1:123456789:image/jenkins-preset-recipe/0.0.2/2

2025-03-24T02:08:50.895+05:30
Image transitioned to AVAILABLE state for Image ARN: arn:aws:imagebuilder:us-east-1:123456789:image/jenkins-preset-recipe/0.0.2/2

```

---

## 📝 Notes & Best Practices

- Always validate shell syntax, indentation, and cron entries

- Use version control on:

    Components

    Image recipes

    Infrastructure configuration

- 🔄 You can restrict S3 access in the role policy to avoid over-permission:

  ```json
  {
    "Effect": "Allow",
    "Action": "s3:PutObject",
    "Resource": "arn:aws:s3:::logs-general/*"
  }