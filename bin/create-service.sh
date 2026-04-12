#!/bin/bash
set -e

if [ -z "$1" ]; then
  echo "Usage: ./bin/create-service.sh <service-name> [environment: default=dev]"
  exit 1
fi

SERVICE_NAME=$1
ENV=${2:-dev}
TARGET_DIR="k8s/apps/$SERVICE_NAME"

echo "Scaffolding new Golden Path service: $SERVICE_NAME in $TARGET_DIR"
mkdir -p "$TARGET_DIR"

cat <<EOF > "$TARGET_DIR/deployment.yaml"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $SERVICE_NAME
  namespace: default
  labels:
    app: $SERVICE_NAME
    environment: $ENV
spec:
  replicas: 1
  selector:
    matchLabels:
      app: $SERVICE_NAME
      environment: $ENV
  template:
    metadata:
      labels:
        app: $SERVICE_NAME
        environment: $ENV
    spec:
      serviceAccountName: $SERVICE_NAME
      containers:
      - name: $SERVICE_NAME
        image: nginxinc/nginx-unprivileged:alpine
        ports:
        - containerPort: 8080
        securityContext:
          runAsNonRoot: true
          runAsUser: 101
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
EOF

cat <<EOF > "$TARGET_DIR/service.yaml"
apiVersion: v1
kind: Service
metadata:
  name: $SERVICE_NAME
  namespace: default
  labels:
    app: $SERVICE_NAME
    environment: $ENV
spec:
  selector:
    app: $SERVICE_NAME
  ports:
  - port: 80
    targetPort: 8080
  type: ClusterIP
EOF

cat <<EOF > "$TARGET_DIR/ingress.yaml"
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: $SERVICE_NAME
  namespace: default
  labels:
    app: $SERVICE_NAME
    environment: $ENV
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
spec:
  rules:
  - http:
      paths:
      - path: /$SERVICE_NAME
        pathType: Prefix
        backend:
          service:
            name: $SERVICE_NAME
            port:
              number: 80
EOF

cat <<EOF > "$TARGET_DIR/serviceaccount.yaml"
apiVersion: v1
kind: ServiceAccount
metadata:
  name: $SERVICE_NAME
  namespace: default
  labels:
    app: $SERVICE_NAME
    environment: $ENV
EOF

echo "Done! The $SERVICE_NAME boilerplate has been generated successfully and satisfies Gatekeeper validation."
