# 🚀 GitOps Pipeline: GitHub Actions + Terraform + ECS Fargate (Blue/Green)

[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.9-844FBA?logo=terraform&logoColor=white)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-us--east--1-FF9900?logo=amazon-aws&logoColor=white)](https://aws.amazon.com/)
[![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-2088FF?logo=github-actions&logoColor=white)](https://github.com/features/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A production-ready, open-source GitOps infrastructure and CI/CD delivery pipeline on AWS using Terraform as Infrastructure as Code (IaC). Every push to the `main` branch triggers an automated workflow that builds, scans, updates infrastructure, and deploys containers using zero-downtime **Blue/Green deployments** managed by AWS CodeDeploy and protected by automated CloudWatch rollbacks.

---

## 📌 Table of Contents

- [Overview](#-overview)
- [Architecture & Workflow](#-architecture--workflow)
- [Tech Stack](#-tech-stack)
- [Project Scope](#-project-scope)
- [Implementation Progress](#-implementation-progress)
- [Repository Structure](#-repository-structure)
- [Architecture Decisions & FAQ](#-architecture-decisions--faq)
- [Estimated AWS Costs](#-estimated-aws-costs)
- [Prerequisites](#-prerequisites)
- [Next Steps](#-next-steps)
- [License](#-license)

---

## 🎯 Overview

This project provides an enterprise-grade reference architecture for modern container delivery:
- **Zero Static AWS Credentials:** Authenticates GitHub Actions to AWS via OpenID Connect (OIDC) with fine-grained repository trust policies.
- **GitOps State Management:** S3 Remote Backend with DynamoDB state locking to prevent concurrent deployment collisions.
- **Zero-Downtime Blue/Green Deployments:** Traffic shifting handled by AWS CodeDeploy with canary/linear routing (`Linear10PercentEvery1Minutes`).
- **Resilient Observability:** Real-time CloudWatch Alarms for target response errors (5xx) and CPU/Memory thresholds that trigger automatic rollbacks.
- **Auto-Healing Scalability:** Application Auto Scaling automatically adjusts ECS tasks between 2 and 8 instances based on average CPU target tracking (60%).

---

## 📐 Architecture & Workflow

```text
               Git Push to main branch
                         │
                         ▼
        ┌───────────────────────────────────┐
        │       GitHub Actions Runner       │
        └─────────────────┬─────────────────┘
                          │ (OIDC JWT Auth - No Access Keys)
                          ▼
        ┌───────────────────────────────────┐
        │             AWS IAM               │
        └───────┬───────────────────┬───────┘
                │                   │
   [1] Build & Push            [2] Terraform Apply
                ▼                   ▼
      ┌──────────────────┐ ┌──────────────────┐
      │   Amazon ECR     │ │  S3 + DynamoDB   │
      │  (Docker Image)  │ │ (Remote Backend) │
      └─────────┬────────┘ └────────┬─────────┘
                │                   │
                └─────────┬─────────┘
                          ▼
        ┌───────────────────────────────────┐
        │           AWS CodeDeploy          │
        └─────────────────┬─────────────────┘
                          │ (Linear10PercentEvery1Minute)
                          ▼
       ┌─────────────────────────────────────┐
       │     Application Load Balancer       │
       │    Port 80 (Prod) / 8080 (Test)     │
       └─────────┬─────────────────┬─────────┘
                 │ (Live)          │ (Staging / Bake Time)
                 ▼                 ▼
          ┌─────────────┐   ┌─────────────┐
          │  Target Gp  │   │  Target Gp  │
          │   (Blue)    │   │   (Green)   │
          └──────┬──────┘   └──────┬──────┘
                 │                 │
                 ▼                 ▼
          ┌───────────────────────────────┐
          │      Amazon ECS (Fargate)     │
          │       Node.js REST API        │
          └──────────────┬────────────────┘
                         │
           CloudWatch Alarms & Auto Rollback
                         │
                         ▼
          ┌───────────────────────────────┐
          │          Amazon SNS           │
          │     (Email Notification)      │
          └───────────────────────────────┘
```

---

## 🧱 Tech Stack

| Domain | Technology | Description |
|---|---|---|
| **IaC** | Terraform `>= 1.9` / AWS Provider `~> 6.0` | Modular, declarative cloud provisioning |
| **Cloud Provider** | AWS (`us-east-1`) | Multi-AZ resilient cloud architecture |
| **CI/CD** | GitHub Actions | Automated build, test, and release automation |
| **Authentication** | IAM OIDC Web Identity | Keyless authentication for runners |
| **Container Runtime** | Amazon ECS Fargate | Serverless container execution |
| **Registry** | Amazon ECR | Private Docker container image registry |
| **Deployment Engine** | AWS CodeDeploy | Blue/Green traffic shifting & auto-rollback |
| **State Storage** | AWS S3 + DynamoDB | Distributed state storage and locking |
| **Load Balancing** | Application Load Balancer (ALB) | Dual target groups (Blue/Green) + Test listener |
| **Observability** | CloudWatch Metrics & Alarms | Deployment health checks and error alarms |
| **Notifications** | Amazon SNS | Deployment success/failure alerts |
| **Application** | Node.js (Express) | Lightweight REST microservice with `/health` |

---

## 📊 Implementation Progress

### Sprint Breakdown

- [x] **Sprint 1: Bootstrap & Foundational Security (In Progress)**
  - [x] Project directory hierarchy and `.gitignore` setup
  - [x] Bootstrap configuration variables (`variables.tf`)
  - [x] S3 remote backend bucket with versioning and AES256 encryption (`main.tf`)
  - [x] DynamoDB lock table with `LockID` primary key (`main.tf`)
  - [x] IAM OpenID Connect (OIDC) Identity Provider for GitHub Actions (`main.tf`)
  - [x] IAM Role with scoped repository Trust Policy (`main.tf`)
  - [x] IAM Permission Policy for CI/CD actions (`main.tf`)
  - [ ] Bootstrap Output variables (`outputs.tf`)
  - [ ] Execute bootstrap provisioning (`terraform apply`)

- [ ] **Sprint 2: Network, Security & Registry Modules**
  - [ ] Module `network`: VPC `10.5.0.0/16`, 2 AZs, Public/Private subnets, NAT Gateways
  - [ ] Module `security`: Security Groups for ALB (80/8080) and ECS Tasks (3000)
  - [ ] Module `ecr`: Private repository, image scanning on push, lifecycle retention rules

- [ ] **Sprint 3: Ingress, Runtime & CodeDeploy Modules**
  - [ ] Module `alb`: ALB, Target Groups (Blue & Green), Listeners (80 & 8080)
  - [ ] Module `ecs`: Fargate Cluster, Task Definition (512 CPU / 1GB RAM), Service
  - [ ] Module `codedeploy`: Application, Deployment Group, traffic routing configuration

- [ ] **Sprint 4: Scalability, Monitoring & Alerts**
  - [ ] Module `autoscaling`: ECS Target Tracking (60% CPU utilization, 2-8 tasks)
  - [ ] Module `monitoring`: CloudWatch Alarms (High CPU, Memory, ALB 5xx errors)
  - [ ] Module `notifications`: SNS Topic, email subscription, CodeDeploy triggers

- [ ] **Sprint 5: Microservice Demo Application**
  - [ ] Express.js application (`server.js`) with `/` and `/health` endpoints
  - [ ] Production-ready multi-stage `Dockerfile`

- [ ] **Sprint 6: GitHub Actions Workflows**
  - [ ] `.github/workflows/deploy.yml`: OIDC login, build, test, terraform apply, deploy
  - [ ] `.github/workflows/destroy.yml`: Safe manual teardown workflow

---

## 📂 Repository Structure

```text
.
├── .github/
│   └── workflows/
│       ├── deploy.yml             # Main GitOps pipeline
│       └── destroy.yml            # Manual teardown workflow
├── app/
│   ├── server.js                  # Express.js REST application
│   ├── package.json               # Dependencies and scripts
│   └── Dockerfile                 # Container image specification
├── terraform/
│   ├── bootstrap/                 # One-time bootstrap (S3, DynamoDB, OIDC)
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── modules/
│   │   ├── network/               # VPC, Subnets, Gateways, Routes
│   │   ├── security/              # Security Groups
│   │   ├── ecr/                   # Container Registry & Lifecycle
│   │   ├── alb/                   # Load Balancer & Blue/Green Target Groups
│   │   ├── ecs/                   # ECS Fargate Cluster, Service, Task Def
│   │   ├── codedeploy/            # CodeDeploy App & Deployment Group
│   │   ├── autoscaling/           # Target Tracking Auto Scaling
│   │   ├── monitoring/            # CloudWatch Alarms
│   │   └── notifications/         # SNS Topic & Alert Subscriptions
│   ├── main.tf                    # Root composition orchestrator
│   ├── variables.tf               # Root input variables
│   ├── outputs.tf                 # Root output exports
│   ├── backend.tf                 # S3 Remote state connection
│   └── terraform.tfvars.example   # Example variable overrides
├── scripts/
│   └── create_deployment.sh       # CodeDeploy helper deployment script
├── README.md                      # Comprehensive project documentation
└── .gitignore                     # Git ignore rules
```

---

## ❓ Architecture Decisions & FAQ

### Why OIDC instead of long-lived AWS IAM Access Keys?
Long-lived access keys (`AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`) stored in GitHub Secrets are one of the most common attack vectors for cloud breaches. OpenID Connect eliminates stored secrets completely by issuing dynamic, cryptographic, short-lived tokens valid only for the duration of the pipeline run.

### Why AWS CodeDeploy for ECS instead of the default rolling update?
The standard ECS rolling deployment replaces containers gradually behind the same target group, making testing and instant rollback difficult. With CodeDeploy Blue/Green:
1. A completely fresh Green environment is spun up.
2. Health checks run on an isolated test port (`8080`).
3. Traffic is shifted gradually (`Linear10PercentEvery1Minutes`).
4. If any CloudWatch Alarm triggers or health checks fail, traffic immediately shifts back to Blue with zero user impact.

### Why S3 + DynamoDB for Terraform Backend?
Storing state locally or inside Git commits causes concurrency conflicts, loss of state file history, and potential leaks of sensitive variable data. S3 provides encrypted, versioned remote storage, while DynamoDB provides atomic locking to prevent concurrent runs from corrupting state.

---

## 💰 Estimated AWS Costs

Approximate monthly cost running 24/7 in `us-east-1` (development/testing estimation):

| Resource | Configuration | Estimated Cost / Month |
|---|---|---|
| **ECS Fargate** | 2 tasks (0.5 vCPU / 1 GB RAM) | ~$15.00 |
| **NAT Gateways** | 2x NAT Gateways (Multi-AZ) | ~$64.00 |
| **Application Load Balancer** | 1 ALB with 2 Listeners | ~$16.00 |
| **Amazon ECR** | Image storage (< 10 images) | ~$1.00 |
| **CloudWatch Logs & Metrics** | 7-day retention + Alarms | ~$2.00 |
| **S3 + DynamoDB** | State storage and locking | < $1.00 |
| **Amazon SNS** | Email notifications | $0.00 (Free Tier) |
| **Total Estimated** | | **~$99.00 / month** |

> ⚠️ **Cost Saving Tip:** To minimize charges during study, run the manual `destroy.yml` pipeline or `terraform destroy` when not actively developing.

---

## ⚙️ Prerequisites

Before getting started, make sure you have installed:
- [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) configured with administrative credentials.
- [Terraform `>= 1.9`](https://developer.hashicorp.com/terraform/downloads).
- [Docker](https://docs.docker.com/get-docker/) for local container testing.
- [Git](https://git-scm.com/).

---

## 🚀 Next Steps

We are currently finishing **Sprint 1**:
1. Configure `terraform/bootstrap/outputs.tf`.
2. Execute `terraform init` and `terraform apply` inside `terraform/bootstrap/` to generate the S3 bucket, DynamoDB lock table, and GitHub Actions OIDC Role.
3. Advance to **Sprint 2** to build the VPC and networking infrastructure!

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
