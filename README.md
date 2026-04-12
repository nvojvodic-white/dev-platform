# dev-platform

A production-grade Internal Developer Platform built on AWS, demonstrating infrastructure ownership, GitOps delivery, security hardening, and full-stack observability.

## Architecture

- **AWS VPC** — Multi-AZ network with public/private subnets, NAT Gateway, and least-privilege routing
- **EKS** — Managed Kubernetes cluster (v1.32) with auto-scaling node groups
- **Argo CD** — GitOps continuous delivery; all cluster state is driven from this repository
- **Prometheus + Grafana** — Full observability stack with pre-built Kubernetes dashboards
- **Remote Terraform State** — S3 backend with DynamoDB locking for team collaboration
- **Network Policies** — Default-deny with explicit allow rules per service
- **Trivy** — IaC security scanning on every push

## CI/CD Pipeline

| Trigger | Action |
|---|---|
| Pull Request opened | Terraform plan + comment on PR |
| Merge to main | Terraform apply with production approval gate |
| Every push | Trivy security scan |

## Stack

| Layer | Tool |
|---|---|
| Infrastructure as Code | Terraform |
| Remote State | S3 + DynamoDB |
| Container Orchestration | Kubernetes (EKS) |
| GitOps / CD | Argo CD |
| Monitoring | Prometheus + Grafana |
| Security Scanning | Trivy |
| CI/CD | GitHub Actions |
| Cloud Provider | AWS |

## Repository Structure
dev-platform/
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

### 3. Install Argo CD
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
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
- Security scanning integrated into every PR
- Multi-AZ high availability architecture
- Least-privilege IAM and IRSA for workload identity
