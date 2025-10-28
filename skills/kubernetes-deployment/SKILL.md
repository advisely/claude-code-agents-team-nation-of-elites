---
name: kubernetes-deployment
description: Kubernetes deployment patterns, service mesh, autoscaling, configuration management, and production-ready k8s architecture
---

# Kubernetes Deployment Patterns

## When to Use This Skill

- Deploying applications to Kubernetes
- Implementing microservices on k8s
- Setting up autoscaling and load balancing
- Managing Kubernetes configurations
- Production k8s best practices

## Target Agents

- `devops-engineer` - Primary user
- `cloud-architect` - K8s architecture
- `backend-developer` - Application deployment

## Core Patterns

### 1. Deployment Configuration

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  labels:
    app: web-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      containers:
      - name: web-app
        image: myregistry.com/web-app:v1.0.0
        ports:
        - containerPort: 8080
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: database-url
```

### 2. Service Configuration

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-app-service
spec:
  selector:
    app: web-app
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
  type: LoadBalancer
---
apiVersion: v1
kind: Service
metadata:
  name: web-app-internal
spec:
  selector:
    app: web-app
  ports:
  - protocol: TCP
    port: 8080
  type: ClusterIP
```

### 3. Horizontal Pod Autoscaler

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: web-app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web-app
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

### 4. ConfigMap and Secrets

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  app.properties: |
    server.port=8080
    logging.level=INFO
---
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
data:
  database-url: <base64-encoded-value>
  api-key: <base64-encoded-value>
```

### 5. Ingress Configuration

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-app-ingress
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls:
  - hosts:
    - example.com
    secretName: example-com-tls
  rules:
  - host: example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-app-service
            port:
              number: 80
```

## Best Practices

1. Use **resource limits** and requests
2. Implement **health checks** (liveness/readiness)
3. Use **ConfigMaps** for configuration
4. Store secrets in **Secrets** resources
5. Implement **HPA** for autoscaling
6. Use **namespaces** for isolation
7. Implement **RBAC** for security
8. Use **StatefulSets** for stateful apps
9. Implement **PodDisruptionBudgets**
10. Monitor with **Prometheus/Grafana**
