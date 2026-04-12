# Incident Response & Operations Runbook

## Table of Contents
1. [Incident Response Protocol](#incident-response-protocol)
2. [Severity Definitions](#severity-definitions)
3. [Common Mitigations](#common-mitigations)
4. [General Operations](#general-operations)

---

## Incident Response Protocol

### 1. Declare & Page (Incident Commander)
- PagerDuty or OpsGenie alert is triggered via Prometheus.
- The on-call engineer becomes the **Incident Commander (IC)**.
- Start an incident bridge (Slack `/incident` integration or Zoom).

### 2. Triage & Communication
- Acknowledge the alert within 5 minutes.
- Determine the Severity Level map (see below).
- Post an initial status update to `#incidents` and `status.dev-platform.com`.

### 3. Mitigate 
- The primary goal of an incident is *mitigation of customer pain*, not determining root cause.
- Roll back to the previous known-good deployment if feasible (see [Common Mitigations](#common-mitigations)).

### 4. Resolve & Post-Mortem
- Confirm telemetry is stable and SLO Error Budgets are recovering.
- Resolve the PagerDuty alert.
- Schedule a blameless Post-Mortem within 48 hours for any SEV-1 or SEV-2.

---

## Severity Definitions

| Level | Definition | Target Response (SLA) | Escalate To |
|---|---|---|---|
| **SEV-1** | Critical customer impact. Core services down. SLO violated. | 5 minutes | VP of Engineering |
| **SEV-2** | Partial outage. Major feature broken, no workaround. | 15 minutes | Sr. Engineering Manager |
| **SEV-3** | Minor degradation. Intermittent errors. Workaround exists. | 2 hours | Team Lead |

---

## Common Mitigations

### 🔴 Argo Rollout Canary Failing (Abort)
If a newly deployed canary is failing validation or burning error budget:
```bash
kubectl argo rollouts abort sample-app -n default
```
This forces 100% of traffic back to the known-good ReplicaSet.

### 🔴 Node Capacity Exhausted (Karpenter)
If Karpenter isn't scaling fast enough or AWS is out of Spot capacity:
1. Verify pending pods: `kubectl get pods -A | grep Pending`
2. Check Karpenter logs: `kubectl logs -l app.kubernetes.io/name=karpenter -n karpenter`
3. Fallback: Force On-Demand instances by editing the `NodePool` to exclude Spot.

### 🔴 Database Connection Failed (IRSA)
If the pod cannot connect to the RDS PostgreSQL instance:
1. Ensure the `sample-app` Service Account is correctly annotated with the OIDC Role ARN.
2. Check PostgreSQL connection logs for STS Token validation failures.
3. Verify VPC Security Groups in Terraform allow port 5432.

### 🔴 Argo CD Out of Sync
Force a hard GitOps sync to rewrite cluster state back to the GitHub Truth:
```bash
kubectl patch app sample-app -n argocd --type merge \
  -p '{"operation": {"initiatedBy": {"username": "admin"}, "sync": {"revision": "HEAD"}}}'
```

---

## General Operations

### Connect to the Cluster
```bash
aws eks update-kubeconfig --region us-east-1 --name dev-platform-dev
```

### Access Dashboards securely
```bash
# Grafana
kubectl port-forward svc/kube-prometheus-stack-grafana -n monitoring 3000:80
```
Open http://localhost:3000 — admin/admin123

```bash
# Argo CD
kubectl port-forward svc/argocd-server -n argocd 8080:443
```
Open https://localhost:8080 — admin/<initial-secret>

### Start/Stop Session
```bash
# Stop dev environment to save cloud costs
cd terraform && terraform destroy
```
