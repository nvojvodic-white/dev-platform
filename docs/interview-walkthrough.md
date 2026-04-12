# Interview Walkthrough: dev-platform

This document is a structured guide for presenting the `dev-platform` project during a technical interview for a Senior DevOps / Platform Engineering / SRE role.

---

## Part 1: Opening Statement (60 seconds)

> *"I built this project as a production-grade Internal Developer Platform on AWS to demonstrate end-to-end infrastructure ownership. Rather than just deploying a simple Kubernetes cluster, I wanted to showcase the full operational lifecycle of a real platform — from provisioning infrastructure with Terraform, through securing it with policy enforcement, all the way to progressive delivery, mathematical SLO tracking, and formal incident response protocols.*
>
> *The goal was to build something that could genuinely serve as the backbone of a small engineering organisation, not just a demo. Every decision here reflects something you'd see in a mature, production environment."*

---

## Part 2: The Live Dashboard (2–3 minutes)

**Action:** Open the dashboard in the browser.

> *"The first thing I want to show you is the platform command center. This is a live dashboard deployed as a Kubernetes workload, served behind an AWS Application Load Balancer."*

**Point out:**
- The **"Platform Online"** pulse badge in the header — signals the EKS cluster and ALB Ingress are functioning.
- The **Kubernetes v1.34** metric card — proves we're running the latest stable EKS release.
- The **Karpenter (Spot)** node counter — explain it fluctuates because Karpenter provisions nodes dynamically based on workload resource requirements, mixing Spot and On-Demand for cost efficiency.
- The **SLO Latency (p99)** card — explain this represents our 99th percentile response time target, tracked mathematically by Prometheus.
- **DORA Metrics panel** — *"All four metrics are in the Elite performer band, meaning we can deploy multiple times per day with a sub-15-minute MTTR."*
- **Live Service Mesh Topology** — walk through the animated traffic flow: ALB → Argo Rollout Pod → RDS PostgreSQL. Highlight that the DB connection is **passwordless** using AWS IAM STS tokens.

---

## Part 3: The Infrastructure (Terraform) (3–4 minutes)

**Action:** Open `terraform/main.tf` and `terraform/modules/eks/main.tf`.

> *"All infrastructure is defined as code using Terraform, broken into reusable, single-responsibility modules."*

**Walk through:**
- `modules/vpc/` — Multi-AZ VPC with private subnets so no workloads are ever exposed directly to the internet.
- `modules/eks/main.tf` — EKS v1.34 cluster. Point out the `cluster_version` variable. *"I keep this pinned and increment it deliberately, following AWS's required sequential minor version upgrade path."*
- `modules/eks/karpenter.tf` — *"This is where I replaced the legacy Cluster Autoscaler with Karpenter. Karpenter provisions perfectly sized nodes in milliseconds, whereas the old autoscaler took 3–5 minutes and often over-provisioned."*
- `modules/eks/irsa-sample-app.tf` — *"This is the IRSA configuration. Rather than injecting database passwords as Kubernetes Secrets, the `sample-app` Service Account is bound to an IAM Role that grants an `rds-db:connect` permission. AWS STS exchanges a short-lived OIDC token for database credentials automatically — no secrets in git, no secrets in env vars."*
- `modules/rds/main.tf` — *"The RDS PostgreSQL instance has `iam_database_authentication_enabled = true`, which is what makes passwordless authentication possible."*
- `backend.tf` — *"All Terraform state is stored remotely in an S3 bucket with DynamoDB locking to prevent race conditions when multiple engineers run Terraform simultaneously."*

---

## Part 4: GitOps & Progressive Delivery (3 minutes)

**Action:** Open `k8s/apps/sample-app/rollout.yaml`.

> *"Deployments are driven entirely by GitOps via Argo CD. A git push to main is the only mechanism that changes the cluster state. Human SSH access to the cluster is not required."*

**Walk through:**
- The file is an `argoproj.io/v1alpha1` `Rollout`, not a standard `Deployment`. *"This is the key. Standard Kubernetes Deployments do a naive rollout — they kill the old pods and spin up new ones immediately. If there's a bug in the new image, everyone is affected at once."*
- Point to the `canary` strategy:
  ```yaml
  steps:
  - setWeight: 20
  - pause: {}
  - setWeight: 100
  ```
  *"With this config, when we push a new image, Argo routes only 20% of production traffic to the new version and then pauses. A human operator validates the canary against our SLO metrics in Grafana. If metrics look good: `kubectl argo rollouts promote sample-app`. If there's a regression, we abort instantly: `kubectl argo rollouts abort sample-app` — 100% traffic reverts to the known-good version in under 5 seconds."*

---

## Part 5: Real SLOs & Error Budgets (3 minutes)

**Action:** Open `k8s/monitoring/slos.yaml`, then switch to the Grafana browser tab.

> *"Most teams say they 'monitor their services'. What differentiates senior SRE work is defining mathematical Service Level Objectives and tracking Error Budget consumption."*

**Walk through `slos.yaml`:**
- `sli:availability:ratio` — *"This PromQL expression divides successful 2xx HTTP responses by total responses, yielding an availability ratio. If this drops below 0.999, we are burning through our 99.9% SLO Error Budget."*
- `sli:latency:p99` — *"This continuously tracks the 99th percentile latency of our sample-app ingress. The p99 is what your worst 1% of users experience — that's the number that matters for real user experience."*
- `SampleAppAvailabilitySLOBurnHigh` alert — *"If the ratio stays below 0.999 for 5 minutes, this alert fires directly to PagerDuty."*

**In Grafana:**
- Navigate to Explore → type `sli:availability:ratio`.
- *"You can see the SLI is registered in the Prometheus data engine. In a traffic-bearing environment, this graph would show our exact burn rate against the 99.9% objective in real time."*

---

## Part 6: Security & Compliance (2 minutes)

**Action:** Open `.github/workflows/security.yml`.

> *"Security is shift-left here — it's not an afterthought that happens at deployment time."*

**Walk through:**
- **Trivy** — scans all container images for CVEs on every commit.
- **Checkov** — scans all Terraform files for IaC misconfigurations (open S3 buckets, missing encryption, public security groups) on every PR. A failed Checkov scan blocks the merge.
- **OPA Gatekeeper** — admission controller that enforces that every workload deployed to the cluster *must* carry `app` and `environment` labels. Unlabelled pods are rejected at the Kubernetes API server before they ever schedule.
- **Network Policies** — default-deny posture. Every pod is isolated from every other pod unless an explicit allow rule is written.

---

## Part 7: FinOps & Cost Governance (1 minute)

**Action:** Open `.github/workflows/terraform.yml`.

> *"Every Pull Request that touches Terraform automatically gets an Infracost comment showing the exact monthly cost delta of the proposed infrastructure change — before anyone approves the merge."*

- *"This prevents the classic scenario where an engineer accidentally provisions an `m5.24xlarge` RDS instance and nobody notices until the AWS bill arrives at the end of the month."*

---

## Part 8: Developer Experience (1 minute)

**Action:** Open `bin/create-service.sh`.

> *"The Golden Path script is the developer-facing API of this platform. A new engineer on day one can run `./bin/create-service.sh my-service` and get a fully scaffolded, production-ready, Gatekeeper-compliant set of Kubernetes manifests — Deployment, Service, Ingress, ServiceAccount — without needing to understand any of the underlying platform complexity."*

---

## Part 9: Incident Response (1 minute)

**Action:** Open `docs/runbook.md`.

> *"Finally, a platform is only as good as its ability to recover from failure. This runbook defines formal SEV-1 through SEV-3 severity levels, Incident Commander responsibilities, SLA response targets, and specific remediation commands mapped to each failure scenario — including exactly how to abort an Argo Rollout canary and how to diagnose Karpenter node provisioning failures."*

---

## Part 10: Closing Statement

> *"Together, this platform covers the complete operational surface area of a modern engineering organisation: infrastructure provisioning, GitOps delivery, progressive releases, mathematical reliability tracking, cost governance, security compliance, developer experience, and operational readiness. I'm happy to go deep on any individual component."*

---

---

# Likely Interviewer Questions & Model Answers

---

### Q: Why did you choose Karpenter over the Cluster Autoscaler?

> *"The Cluster Autoscaler works at the Auto Scaling Group level — it waits for a pod to be Pending, then slowly increments the ASG desired count and waits for AWS to provision the node, which typically takes 3–5 minutes. Karpenter watches the Kubernetes scheduler directly and provisions nodes in under 60 seconds by calling the EC2 Fleet API immediately. It also does bin-packing much more efficiently — it selects the exact right instance type for the pending workload rather than always provisioning from a fixed set of ASG instance types. For cost and speed, Karpenter is a clear upgrade."*

---

### Q: How does the passwordless database authentication actually work under the hood?

> *"The EKS cluster has an OIDC provider attached. When a pod starts with a Kubernetes Service Account that is annotated with an IAM Role ARN, Kubernetes injects an OIDC token into the pod's filesystem. The AWS SDK running in the application automatically exchanges that token with AWS STS for a temporary IAM credential. For RDS, instead of presenting a password, you call `generate-db-auth-token` which produces a short-lived (15-minute) auth token signed by that IAM credential. RDS validates the token against IAM and grants access. No static secret ever exists anywhere."*

---

### Q: What happens if someone pushes a bad canary — how quickly can you roll back?

> *"With Argo Rollouts, a rollback is a single command: `kubectl argo rollouts abort sample-app`. It takes approximately 5 seconds — Argo just shifts the traffic weight selector back to 100% on the stable ReplicaSet. No new pods need to spin up, no containers need to be pulled. The old pods are still running during the canary window. Compare that to a standard Kubernetes Deployment rollback which triggers a new rollout cycle and could take 2–3 minutes depending on readiness probes."*

---

### Q: What does a 99.9% SLO actually mean in practice?

> *"A 99.9% availability SLO means you have an Error Budget of 0.1% downtime per month. Over 30 days, that's approximately 43 minutes of allowable downtime. If you consume that budget — say through a bad deployment, a node failure, or infrastructure issues — all further feature releases should pause until the budget replenishes. The Prometheus rule we defined alerts at the burn-rate level, not just when the SLO is violated, so we can catch a high error rate and intervene before we've exhausted the monthly budget."*

---

### Q: How would you extend this platform for a team of 50 engineers?

> *"A few key additions: First, I'd introduce Crossplane or Backstage as a self-service infrastructure portal so engineers can provision databases and queues without writing Terraform directly. Second, I'd add multi-environment Argo CD ApplicationSets to manage dev/staging/prod namespaces from a single Git repo structure. Third, I'd implement strict RBAC with SSO integration so engineers have read-only cluster access by default and require break-glass procedures for write access. Fourth, I'd add a Slack integration to Argo Rollouts so canary promotions can be voted on and approved directly from a Slack channel without anyone needing kubectl access."*

---

### Q: The Infracost integration — what does it actually output on a PR?

> *"Infracost posts a detailed comment on the Pull Request showing the monthly cost breakdown by Terraform resource — broken down by EC2 node groups, RDS instance, NAT Gateway, Load Balancer, and data transfer. It shows the previous cost, the new cost, and the delta. If a change is going to increase the monthly bill by $500, that becomes a visible, documented part of the code review process rather than a surprise."*

---

### Q: How do you handle secrets in this platform?

> *"We use a layered approach. First, we eliminate secrets wherever possible using IRSA — the RDS connection uses IAM auth tokens, the ALB controller uses IRSA, the cluster autoscaler uses IRSA. For secrets that genuinely must exist (like third-party API keys), the pattern is to store them in AWS Secrets Manager and use the AWS Secrets Manager CSI driver to inject them as ephemeral volume mounts into the pod's filesystem at runtime. That means no secrets in git, no secrets in Kubernetes Secrets (which are base64-encoded, not encrypted by default), and no secrets in environment variables that could be leaked through process inspection."*

---

### Q: Why not just use ECS instead of EKS?

> *"ECS is an excellent choice for pure AWS environments with simpler workloads. EKS is a better fit when you need multi-cloud portability, a rich ecosystem of CNCF tooling (Argo, Karpenter, OPA, Prometheus), or when you're managing a diverse set of microservices with complex traffic routing requirements. ECS also doesn't support progressive delivery primitives natively — you'd need App Mesh and CodeDeploy to approximate what Argo Rollouts provides out of the box on Kubernetes. For a platform engineering context where the goal is to host and manage many internal teams' workloads, Kubernetes' RBAC model, namespace isolation, and ecosystem maturity make it the right call."*

---

### Q: What would you do differently if you were starting this from scratch today?

> *"A few things. I'd explore using OpenTofu rather than Terraform given the recent licensing changes with HashiCorp. I'd also look at using Pulumi instead of Terraform for teams who prefer defining infrastructure in a real programming language rather than HCL — it enables much richer testing with unit test frameworks. I'd add Crossplane CRDs earlier so developers could provision their own RDS instances without filing tickets. And I'd connect the DORA metrics to a real data source — GitHub webhooks feeding into a time-series database so deployment frequency and lead time are tracked automatically, not simulated."*
