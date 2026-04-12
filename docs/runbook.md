# Operations Runbook

## Daily Operations

### Start a session
```bash
cd terraform && terraform apply
aws eks update-kubeconfig --region us-east-1 --name dev-platform-dev
kubectl get nodes
kubectl get pods -A
```

### End a session (stop billing)
```bash
cd terraform && terraform destroy
```

## Incident Response

### Pod not starting
```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name> --previous
```

### Node not ready
```bash
kubectl describe node <node-name>
kubectl get events --sort-by=.metadata.creationTimestamp
```

### Argo CD out of sync
```bash
kubectl patch app <app-name> -n argocd --type merge \
  -p '{"operation": {"initiatedBy": {"username": "admin"}, "sync": {"revision": "HEAD"}}}'
```

## Scaling

### Scale a deployment manually
```bash
kubectl scale deployment <name> --replicas=2
```

### Check resource usage
```bash
kubectl top nodes
kubectl top pods -A
```

## Monitoring

### Access Grafana
```bash
kubectl port-forward svc/kube-prometheus-stack-grafana -n monitoring 3000:80
```
Open http://localhost:3000 — admin/admin123

### Access Argo CD
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```
Open https://localhost:8080 — admin/<initial-secret>

## Key SLOs
- Pod restart rate: < 1/hour per service
- Deployment success rate: > 99%
- Mean time to recovery: < 15 minutes
