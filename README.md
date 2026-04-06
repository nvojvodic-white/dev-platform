# dev-platform

A production-grade Internal Developer Platform built on AWS, demonstrating infrastructure ownership, GitOps delivery, and full-stack observability.

## Architecture

- **AWS VPC** — Multi-AZ network with public/private subnets, NAT Gateway, and least-privilege routing
- **EKS** — Managed Kubernetes cluster (v1.32) with auto-scaling node groups
- **Argo CD** — GitOps continuous delivery; all cluster state is driven from this repository
- **Prometheus + Grafana** — Full observability stack with pre-built Kubernetes dashboards

## Stack

| Layer | Tool |
|---|---|
| Infrastructure as Code | Terraform |
| Container Orchestration | Kubernetes (EKS) |
| GitOps / CD | Argo CD |
| Monitoring | Prometheus + Grafana |
| Cloud Provider | AWS |
| Scripting | Bash |

## Repository Structure
dev-platform/
├── terraform/
│   ├── modules/
│   │   ├── vpc/        # VPC, subnets, NAT gateway
│   │   └── eks/        # EKS cluster, node groups
│   ├── main.tf
│   ├── variables.tf
│   └── provider.tf
├── k8s/
│   ├── apps/
│   │   └── sample-app/ # Sample app deployed via Argo CD
│   └── monitoring/     # Prometheus + Grafana values
└── docs/

## How to Deploy

### Prerequisites
- AWS CLI configured
- Terraform >= 1.0
- kubectl
- Helm >= 3.0

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
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace \
  -f k8s/monitoring/values.yaml
```

### 5. Deploy Sample App via GitOps
```bash
kubectl apply -f k8s/apps/sample-app/
```

## Key Concepts Demonstrated

- Infrastructure as Code with modular Terraform
- GitOps with Argo CD — git is the single source of truth
- Kubernetes workload management and resource limits
- Observability with metrics, dashboards, and alerting
- Multi-AZ high availability architecture
- Least-privilege IAM and network security
