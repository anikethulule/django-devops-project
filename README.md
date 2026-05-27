# Django DevOps CI/CD Pipeline on AWS

This repository demonstrates a complete DevOps CI/CD implementation for deploying a Django application on AWS using **Terraform**, **Jenkins**, **SonarQube**, **Trivy**, **Amazon ECR**, **Amazon EKS**, **ArgoCD**, and **Slack notifications**.

The project follows a GitOps-based deployment model:

- **Jenkins** handles Continuous Integration.
- **ArgoCD** handles Continuous Deployment.
- **GitHub** remains the source of truth for application code and Kubernetes manifests.
- **EKS** runs the Django application.
- **ECR** stores Docker images.

---

## 1. Architecture Overview

```text
Developer
   |
   | 1. Commit and push code
   v
GitHub Repository
   |
   | 2. GitHub webhook triggers Jenkins
   v
Jenkins CI on EC2
   |
   |-- Checkout code
   |-- SonarQube static code analysis
   |-- Docker image build
   |-- Trivy vulnerability scan report
   |-- Login to Amazon ECR
   |-- Push image to Amazon ECR
   |-- Update Kubernetes deployment manifest with new image tag
   |-- Push updated manifest to GitHub
   |
   v
GitHub k8s/deployment.yaml updated
   |
   | 3. ArgoCD detects manifest change
   v
ArgoCD on EKS
   |
   | 4. Syncs desired state
   v
Amazon EKS Cluster
   |
   | 5. Runs Django pods and exposes application using LoadBalancer
   v
Users access Django application URL
```

---

## 2. Tools and Technologies Used

| Tool | Purpose |
|---|---|
| Terraform | Provision AWS infrastructure |
| AWS EC2 | Host Jenkins and SonarQube |
| Jenkins | CI pipeline orchestration |
| GitHub | Source code and Kubernetes manifest repository |
| SonarQube | Static code quality analysis |
| Docker | Build Django application container image |
| Trivy | Container image vulnerability scanning |
| Amazon ECR | Private Docker image registry |
| Amazon EKS | Kubernetes cluster for application runtime |
| ArgoCD | GitOps-based continuous deployment |
| Slack | CI/CD status notifications |

---

## 3. Repository Structure

```text
django-devops-project/
├── app/
│   ├── Dockerfile
│   ├── requirements.txt
│   ├── manage.py
│   └── myproject/
│
├── terraform/
│   ├── provider.tf
│   ├── variables.tf
│   ├── vpc.tf
│   ├── ec2.tf
│   ├── ecr.tf
│   ├── eks.tf
│   ├── security-groups.tf
│   ├── outputs.tf
│   └── user-data/
│       ├── jenkins.sh
│       └── sonarqube.sh
│
├── k8s/
│   ├── namespace.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   └── ingress.yaml
│
├── argocd/
│   └── application.yaml
│
├── Jenkinsfile-CI
├── Jenkinsfile-CD
├── .gitignore
└── README.md
```

---

## 4. Prerequisites

Before starting, make sure you have the following:

### Local Machine Requirements

Install these tools on your local machine:

```bash
aws --version
terraform version
kubectl version --client
git --version
ssh -V
```

Required tools:

- AWS CLI
- Terraform
- kubectl
- Git
- SSH client
- GitHub account
- AWS account
- Slack workspace

---

## 5. AWS CLI Configuration

Configure AWS CLI with your access key and secret key:

```bash
aws configure
```

Provide the following values:

```text
AWS Access Key ID: <YOUR_AWS_ACCESS_KEY>
AWS Secret Access Key: <YOUR_AWS_SECRET_KEY>
Default region name: us-east-1
Default output format: json
```

Verify AWS access:

```bash
aws sts get-caller-identity
```

Expected output:

```json
{
    "UserId": "...",
    "Account": "065209282584",
    "Arn": "arn:aws:iam::065209282584:user/..."
}
```

---

## 6. Provision AWS Infrastructure Using Terraform

Terraform provisions the following AWS resources:

- VPC
- Public and private subnets
- Internet Gateway
- NAT Gateway
- Security Groups
- EC2 instance for Jenkins
- EC2 instance for SonarQube
- Amazon ECR repository
- Amazon EKS cluster
- EKS managed node group
- IAM roles and policies

Go to the Terraform directory:

```bash
cd terraform
```

Initialize Terraform:

```bash
terraform init
```

Validate Terraform configuration:

```bash
terraform validate
```

Review execution plan:

```bash
terraform plan
```

Apply infrastructure:

```bash
terraform apply -auto-approve
```

After deployment, check Terraform outputs:

```bash
terraform output
```

Expected output values:

```text
jenkins_public_ip = <JENKINS_PUBLIC_IP>
sonarqube_public_ip = <SONARQUBE_PUBLIC_IP>
ecr_repository_url = 065209282584.dkr.ecr.us-east-1.amazonaws.com/django-devops-app
eks_cluster_name = django-devops-eks
```

---

## 7. Configure EKS Access

After Terraform creates the EKS cluster, update your kubeconfig:

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name django-devops-eks
```

Verify EKS node access:

```bash
kubectl get nodes
```

Expected output:

```text
NAME                         STATUS   ROLES    AGE   VERSION
ip-10-x-x-x.ec2.internal     Ready    <none>   10m   v1.xx
ip-10-x-x-x.ec2.internal     Ready    <none>   10m   v1.xx
```

Check all namespaces:

```bash
kubectl get pods -A
```

---

## 8. Jenkins Setup

Open Jenkins in the browser:

```text
http://<JENKINS_PUBLIC_IP>:8080
```

Get the initial admin password from the Jenkins EC2 instance:

```bash
ssh -i <YOUR_KEY>.pem ubuntu@<JENKINS_PUBLIC_IP>

sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

Install recommended plugins and then install these additional plugins if not already available:

- Git
- GitHub
- Pipeline
- Pipeline Stage View
- Credentials Binding
- Docker Pipeline
- SonarQube Scanner
- Blue Ocean
- Slack Notification Plugin

---

## 9. Docker Permission for Jenkins User (it is added in jenkins.sh file but if still give issue then use this cmd )

Jenkins pipeline uses Docker to build images. The Linux `jenkins` user must have permission to access Docker.

SSH to Jenkins server:

```bash
ssh -i <YOUR_KEY>.pem ubuntu@<JENKINS_PUBLIC_IP>
```

Add Jenkins user to Docker group:

```bash
sudo usermod -aG docker jenkins
sudo systemctl restart docker
sudo systemctl restart jenkins
```

Verify Docker access as Jenkins user:

```bash
sudo -u jenkins docker ps
```

If permission is still denied, reboot the EC2 instance:

```bash
sudo reboot
```

---

## 10. SonarQube Setup

Open SonarQube in browser:

```text
http://<SONARQUBE_PUBLIC_IP>:9000
```

Default credentials:

```text
Username: admin
Password: admin
```

Change the password after first login.

Create a SonarQube token:

```text
My Account → Security → Generate Token
```


## 11. Configure SonarQube in Jenkins

Go to Jenkins:

```text
Manage Jenkins → System → SonarQube Servers
```

Add SonarQube server:

```text
Name: SonarQube
Server URL: http://<SONARQUBE_PUBLIC_IP>:9000
Server authentication token: sonarqube-token
```

Then configure SonarScanner:

```text
Manage Jenkins → Tools → SonarQube Scanner installations
```

Add:

```text
Name: SonarScanner
Install automatically: Enabled
Version: Latest available
```

---

## 12. Jenkins Credentials Required

Go to:

```text
Manage Jenkins → Credentials → System → Global credentials → Add Credentials
```

Create the following credentials:

| Credential ID | Type | Purpose |
|---|---|---|
| `aws-access-key` | Secret text | AWS access key for ECR login |
| `aws-secret-key` | Secret text | AWS secret key for ECR login |
| `sonarqube-token` | Secret text | SonarQube authentication |
| `github-token` | Username with password | Push updated manifest back to GitHub |
| `slack-webhook-url` | Secret text | Send Slack notifications |

### GitHub Token Permission

For `github-token`, use:

```text
Username: <YOUR_GITHUB_USERNAME>
Password: <GITHUB_PERSONAL_ACCESS_TOKEN>
```


Required permission:

```text
Contents: Read and Write
```

---

## 13. Create Jenkins Pipeline Job

In Jenkins dashboard:

```text
New Item → Pipeline
```

Use:

```text
Item name: devops_Project
Type: Pipeline
```

Configure pipeline:

```text
Pipeline → Definition: Pipeline script from SCM
SCM: Git
Repository URL: https://github.com/anikethulule/django-devops-project.git
Branch: */main
Script Path: Jenkinsfile-CI
```

Enable GitHub webhook trigger:

```text
Build Triggers → GitHub hook trigger for GITScm polling
```

Save the job.

---

## 14. Configure GitHub Webhook

Go to GitHub repository:

```text
Settings → Webhooks → Add webhook
```

Use:

```text
Payload URL: http://<JENKINS_PUBLIC_IP>:8080/github-webhook/
Content type: application/json
Event: Just the push event
Active: Enabled
```

Click **Add webhook**.

---

## 15. CI Pipeline Flow in Jenkins

The `Jenkinsfile-CI` performs the following stages:

| Stage | Description |
|---|---|
| Checkout Code | Pulls latest source code from GitHub |
| SonarQube Static Code Analysis | Runs SonarQube scanner against Django code |
| Build Docker Image | Builds Docker image from `app/Dockerfile` |
| Trivy Security Scan Report | Generates vulnerability scan report |
| Login to ECR | Authenticates Docker to Amazon ECR |
| Push Image to ECR | Pushes build-number tag and latest tag to ECR |
| Update Kubernetes Manifest | Updates `k8s/deployment.yaml` with new image tag |
| Post Actions | Sends Slack success or failure notifications |

---

## 16. Avoid Jenkins Infinite Trigger Loop

Because Jenkins updates `k8s/deployment.yaml` and pushes back to GitHub, GitHub can trigger Jenkins again


For a production-grade design, use two repositories:

```text
Repo 1: Application source code and Jenkinsfile
Repo 2: Kubernetes manifests watched by ArgoCD
```

This completely avoids the self-trigger loop.

---

## 17. Amazon ECR Setup

Terraform should create the ECR repository:

```text
065209282584.dkr.ecr.us-east-1.amazonaws.com/django-devops-app
```

Verify repository:

```bash
aws ecr describe-repositories \
  --region us-east-1 \
  --repository-names django-devops-app
```

List pushed images:

```bash
aws ecr describe-images \
  --region us-east-1 \
  --repository-name django-devops-app
```

---

## 18. Kubernetes Manifests

The `k8s/` directory contains Kubernetes deployment files.

Required files:

```text
k8s/
├── namespace.yaml
├── deployment.yaml
├── service.yaml
```

### namespace.yaml

Creates the application namespace:

```text
namespace: django-app
```

### deployment.yaml

Runs Django application pods.

Important fields:

```text
replicas: 2
containerPort: 8000
imagePullPolicy: Always
DJANGO_ALLOWED_HOSTS: "*"
```

Jenkins updates this image line automatically:

```text
image: 065209282584.dkr.ecr.us-east-1.amazonaws.com/django-devops-app:<BUILD_NUMBER>
```

### service.yaml

Exposes the application using AWS LoadBalancer:

```text
Type: LoadBalancer
Port: 80
TargetPort: 8000
```

---

## 19. Install ArgoCD on EKS

Create namespace:

```bash
kubectl create namespace argocd
```

Install ArgoCD:

```bash
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

Check pods:

```bash
kubectl get pods -n argocd
```

Wait until all pods are running:

```bash
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s
```

Expose ArgoCD server:

```bash
kubectl patch svc argocd-server -n argocd \
  -p '{"spec": {"type": "LoadBalancer"}}'
```

Get ArgoCD LoadBalancer URL:

```bash
kubectl get svc argocd-server -n argocd
```

Open:

```text
https://<ARGOCD_LOADBALANCER_DNS>
```

Get ArgoCD admin password:

```bash
kubectl get secret argocd-initial-admin-secret \
  -n argocd \
  -o jsonpath="{.data.password}" | base64 -d && echo
```

Login:

```text
Username: admin
Password: <OUTPUT_FROM_ABOVE_COMMAND>
```

---

## 20. Configure ArgoCD Application from GUI

Open ArgoCD UI and create a new application.

Go to:

```text
Applications → New App
```

Use the following values:

| Field | Value |
|---|---|
| Application Name | `django-app` |
| Project | `default` |
| Sync Policy | `Automatic` |
| Repository URL | `https://github.com/anikethulule/django-devops-project.git` |
| Revision | `main` |
| Path | `k8s` |
| Cluster URL | `https://kubernetes.default.svc` |
| Namespace | `django-app` |
| Prune Resources | Enabled |
| Self Heal | Enabled |
| Create Namespace | Enabled |

Click **Create**.

Then open the application and click:

```text
SYNC → SYNCHRONIZE
```

Expected status:

```text
App Health: Healthy
Sync Status: Synced
Last Sync: Sync OK
```

---

## 21. ArgoCD Application Manifest Option

Instead of creating the app from GUI, you can apply the ArgoCD application manifest from the `argocd/` directory.

```bash
kubectl apply -f argocd/application.yaml
```

Verify:

```bash
kubectl get applications -n argocd
```

Expected output:

```text
NAME         SYNC STATUS   HEALTH STATUS
django-app   Synced        Healthy
```

---

## 22. Deploy and Validate Application

After Jenkins pushes image and updates the manifest, ArgoCD deploys the application.

Check namespace resources:

```bash
kubectl get all -n django-app
```

Expected output:

```text
pod/django-app-xxxxx   1/1   Running   0   1m
pod/django-app-yyyyy   1/1   Running   0   1m

service/django-app-service   LoadBalancer   <CLUSTER-IP>   <EXTERNAL-DNS>   80:<NODEPORT>/TCP

deployment.apps/django-app   2/2   2   2   1m
```

Get service URL:

```bash
kubectl get svc django-app-service -n django-app
```

Open application in browser:

```text
http://<DJANGO_APP_LOADBALANCER_DNS>
```

Example:

```text
http://a7c5976953aa94bd08419bc0421927e3-831692882.us-east-1.elb.amazonaws.com
```

---

## 23. Verify Application Image Tag

Check which image is currently deployed:

```bash
kubectl get deployment django-app -n django-app \
  -o=jsonpath='{.spec.template.spec.containers[0].image}' && echo
```

Expected output:

```text
065209282584.dkr.ecr.us-east-1.amazonaws.com/django-devops-app:<BUILD_NUMBER>
```

Check rollout status:

```bash
kubectl rollout status deployment/django-app -n django-app
```

Check pods:

```bash
kubectl get pods -n django-app
```

---

## 24. Slack Notification Setup

Create Slack incoming webhook:

```text
Slack → Apps → Incoming Webhooks → Add to Workspace → Select Channel
```

Copy the webhook URL and add it to Jenkins credentials:

```text
Credential ID: slack-webhook-url
Type: Secret text
```

The pipeline sends notifications for:

- Trivy security scan completed
- Docker image pushed to ECR
- Kubernetes manifest updated
- CI/CD pipeline success
- CI/CD pipeline failure

---

## 25. End-to-End Test

Make a small application change inside the `app/` directory.

Commit and push:

```bash
git add .
git commit -m "Test Django CI/CD pipeline"
git push origin main
```

Expected flow:

```text
1. GitHub webhook triggers Jenkins
2. Jenkins runs CI stages
3. SonarQube analysis completes
4. Docker image is built
5. Trivy scan report is generated
6. Image is pushed to ECR
7. deployment.yaml is updated with new image tag
8. Jenkins pushes manifest commit to GitHub
9. ArgoCD detects the Git change
10. ArgoCD deploys new image to EKS
11. Application becomes available through LoadBalancer URL
12. Slack receives pipeline notifications
```

---

## 26. Troubleshooting

### Issue 1: Jenkins pipeline runs again and again

Cause:

```text
Jenkins pushes deployment.yaml to GitHub, and GitHub webhook triggers Jenkins again.
```

Fix:

Use `[skip ci]` in Jenkins auto-commit and skip pipeline if latest commit contains `[skip ci]`.

Recommended long-term fix:

```text
Use separate repositories:
- Application repo
- Kubernetes manifest repo
```

---

### Issue 2: Docker permission denied in Jenkins

Error:

```text
permission denied while trying to connect to the Docker daemon socket
```

Fix:

```bash
sudo usermod -aG docker jenkins
sudo systemctl restart docker
sudo systemctl restart jenkins
sudo -u jenkins docker ps
```

---

### Issue 3: SonarScanner not found

Error:

```text
SonarScanner: not found
```

Fix:

Use correct Linux binary:

```text
sonar-scanner
```

Not:

```text
SonarScanner
```

Also verify Jenkins tool name is:

```text
SonarScanner
```

---

### Issue 4: Trivy scan fails pipeline

If you only want to generate report and continue pipeline, use:

```text
--exit-code 0
```

Avoid:

```text
--exit-code 1
```

unless you intentionally want to fail the build on vulnerabilities.

---

### Issue 5: EKS pod shows ImagePullBackOff

Possible causes:

- Image tag does not exist in ECR
- EKS node role cannot pull from ECR
- Wrong ECR repository URL

Check pod events:

```bash
kubectl describe pod <POD_NAME> -n django-app
```

Attach ECR read-only policy to EKS node role:

```bash
aws iam attach-role-policy \
  --role-name <EKS_NODE_ROLE_NAME> \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly
```

---

### Issue 6: ArgoCD is OutOfSync

Check application:

```bash
kubectl describe application django-app -n argocd
```

Manually sync once from UI:

```text
ArgoCD UI → django-app → Sync → Synchronize
```

---

### Issue 7: Application URL not opening

Check service:

```bash
kubectl get svc django-app-service -n django-app
```

Check endpoints:

```bash
kubectl get endpoints django-app-service -n django-app
```

Check pod logs:

```bash
kubectl logs <POD_NAME> -n django-app
```

Use HTTP, not HTTPS, unless TLS is configured:

```text
http://<LOADBALANCER_DNS>
```

---

## 27. Useful Commands

### Jenkins logs

```bash
sudo journalctl -u jenkins -f
```

### Docker images on Jenkins server

```bash
docker images
```

### Trivy scan manually

```bash
trivy image django-devops-app:latest
```

### ECR images

```bash
aws ecr describe-images \
  --region us-east-1 \
  --repository-name django-devops-app
```

### ArgoCD applications

```bash
kubectl get applications -n argocd
```

### Django app resources

```bash
kubectl get all -n django-app
```

### Current deployment image

```bash
kubectl get deployment django-app -n django-app \
  -o=jsonpath='{.spec.template.spec.containers[0].image}' && echo
```

---

## 28. Production Improvements

For production usage, improve the solution with the following:

| Area | Recommendation |
|---|---|
| Jenkins | Place behind HTTPS reverse proxy or ALB |
| SonarQube | Use supported version and external PostgreSQL |
| Secrets | Use AWS Secrets Manager or Parameter Store |
| AWS IAM | Replace static AWS keys with IAM role-based access |
| GitOps | Use separate app and manifest repositories |
| EKS | Use private subnets and restricted API endpoint |
| Ingress | Use AWS Load Balancer Controller and ACM certificate |
| DNS | Use Route 53 domain instead of raw ELB DNS |
| Security | Fail pipeline on CRITICAL vulnerabilities after baseline cleanup |
| Monitoring | Add Prometheus, Grafana and CloudWatch Container Insights |
| Logging | Centralize logs in CloudWatch or OpenSearch |
| Image policy | Use immutable tags and ECR lifecycle policies |

---

## 29. Final Validation Checklist

Before considering the setup complete, verify:

- [ ] Terraform apply completed successfully
- [ ] Jenkins EC2 is accessible
- [ ] SonarQube EC2 is accessible
- [ ] Jenkins has all required credentials
- [ ] Jenkins can run Docker commands
- [ ] Jenkins can access GitHub repository
- [ ] Jenkins can push to GitHub using `github-token`
- [ ] Jenkins can login and push to ECR
- [ ] EKS nodes are ready
- [ ] ArgoCD is installed and accessible
- [ ] ArgoCD application is `Synced` and `Healthy`
- [ ] Django pods are running
- [ ] Django service has LoadBalancer URL
- [ ] Application is accessible in browser
- [ ] Slack notifications are received
- [ ] Pipeline loop is controlled using `[skip ci]`

---

## 30. Project Summary

This project implements a complete DevOps CI/CD pipeline for a Django application on AWS.

The final flow is:

```text
GitHub Push
   ↓
Jenkins CI
   ↓
SonarQube Code Analysis
   ↓
Docker Image Build
   ↓
Trivy Security Scan Report
   ↓
Amazon ECR Image Push
   ↓
Kubernetes Manifest Update in GitHub
   ↓
ArgoCD GitOps Sync
   ↓
Amazon EKS Deployment
   ↓
Slack Notification
   ↓
Application Available through LoadBalancer URL
```

This setup demonstrates practical CI/CD, DevSecOps, GitOps and cloud-native deployment practices using AWS services and open-source DevOps tools.
