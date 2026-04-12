# dev-platform

A production-grade Internal Developer Platform built on AWS, demonstrating infrastructure ownership, GitOps delivery, security hardening, and full-stack observability.

## Architecture

- **AWS VPC** — Multi-AZ network with public/private subnets, NAT Gateway, and least-privilege routing
- **EKS** — Managed Kubernetes cluster (v1.33) with auto-scaling node groups
- **Argo CD & Rollouts** — GitOps continuous & progressive delivery (Canary deployments)
- **Prometheus & SLOs** — Mathematical Error Budget tracking and full observability stack
- **Remote Terraform State** — S3 backend with DynamoDB locking for team collaboration
- **Network Policies** — Default-deny with explicit allow rules per service
- **Trivy & Checkov** — IaC and container security scanning on every push
- **Infracost** — Cloud cost estimation on Pull Requests
- **Golden Path** — Automated scaffolding script for new microservices

## CI/CD Pipeline

| Trigger | Action |
|---|---|
| Pull Request opened | Terraform plan + Infracost cost estimation comment on PR |
| Merge to main | Terraform apply with production approval gate |
| Every push | Trivy & Checkov security scans |

## Stack

| Layer | Tool |
|---|---|
| Infrastructure as Code | Terraform |
| Remote State | S3 + DynamoDB |
| Container Orchestration | Kubernetes (EKS) |
| GitOps / CD | Argo CD + Argo Rollouts |
| Monitoring & SLOs | Prometheus + Grafana |
| Security Scanning | Trivy + Checkov |
| Cost Optimization | Infracost |
| Developer Tooling | Custom Bash Scaffolding |
| CI/CD | GitHub Actions |
| Cloud Provider | AWS |

## Repository Structure
dev-platform/
├── bin/
│   └── create-service.sh  # Golden Path generator
├── .github/workflows/
│   ├── terraform.yml      # Plan on PR
│   ├── deploy.yml         # Apply on merge with approval
│   └── security.yml       # Trivy scanning
├── terraform/
│   ├── modules/
│   │   ├── vpc/           # VPC, subnets, NAT gateway
│   │   └── eks/           # EKS cluster, node groups, access
│   ├── backend.tf         # S3 remote state
│   ├── main.tf
│   ├── variables.tf
│   └── provider.tf
├── k8s/
│   ├── apps/
│   │   └── sample-app/    # Deployed via Argo CD GitOps
│   ├── monitoring/        # Prometheus + Grafana values
│   └── network-policies/  # Default deny + allow rules
└── docs/
└── runbook.md

## How to Deploy

### Prerequisites
- AWS CLI configured
- Terraform >= 1.0
- kubectl + Helm >= 3.0

### 1. Provision Infrastructure
```bash
cd terraform
terraform init
terraform apply
```

### 2. Connect kubectl
```bash
aws eks update-kubeconfig --region us-east-1 --name dev-platform-dev
```

### 3. Install Argo CD & Rollouts
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

kubectl create namespace argo-rollouts
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml
```

### 4. Install Monitoring
```bash
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace \
  -f k8s/monitoring/values.yaml
```

### 5. Apply Network Policies
```bash
kubectl apply -f k8s/network-policies/
```

## Key Concepts Demonstrated

- Modular Terraform with remote state and state locking
- GitOps with Argo CD — git is the single source of truth
- Full CI/CD with plan, approval gate, and auto-apply
- Zero-trust networking with Kubernetes Network Policies
- Observability with metrics, dashboards, and alerting
- Progressive Delivery with Argo Rollouts (Safe Canary routing)
- Mathematical SLOs & Error Budget alerting via PrometheusRules
- Security scanning and IaC compliance integrated into every PR
- Shift-left cloud cost optimization (FinOps) via Infracost
- Golden Path developer experience via templated service scaffolding
- Multi-AZ high availability architecture
- Least-privilege IAM and IRSA for workload identity
