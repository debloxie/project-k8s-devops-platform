
# 🚀 MicroK8s API Deployment with CI/CD, Monitoring, and Terraform on AWS

This project demonstrates a **production‑style DevOps workflow** using:

- **AWS EC2** for compute  
- **MicroK8s** as a lightweight Kubernetes cluster  
- **Docker Hub** for container image hosting  
- **GitHub Actions** for CI  
- **Manual CD** using Kubernetes rolling updates  
- **Prometheus + Grafana** for monitoring  
- **Terraform** for infrastructure provisioning  

It exposes a public API endpoint and a Grafana dashboard for observability.

---

# 📁 Project Structure

```
.
├── app.py                     # Flask API application
├── requirements.txt           # Python dependencies
├── Dockerfile                 # Docker image definition
│
├── k8s/
│   ├── deployment.yaml        # Kubernetes Deployment for hello-api
│   └── service.yaml           # NodePort service exposing API on port 30080
│
├── terraform/
│   └── main.tf                # Terraform config for EC2 + Security Group
│
├── scripts/
│   └── bootstrap.sh           # User-data script to install MicroK8s on EC2
│
└── .github/
    └── workflows/
        └── deployment.yml             # GitHub Actions pipeline (build + push to Docker Hub)
```

---

# 🌐 Public Endpoints

### **API Endpoint (Hello API)**  
Your Flask API is exposed via a Kubernetes NodePort on **port 30080**.

```
http://44.199.204.3:30080/
```

Expected response:

```
"Hello from Debo's MicroK8s API!"
```

---

### **Grafana Dashboard (Monitoring)**  
Grafana is exposed via NodePort on **port 32000**.

```
http://44.199.204.3:32000/
```

A **read‑only guest account** is available for dashboard viewing:

```
Username: guest
Password: guest
Role: Viewer (read‑only)
```

This account allows safe viewing of dashboards without the ability to modify or delete anything.

---

# 🏗️ Infrastructure (Terraform)

Terraform provisions:

- EC2 instance (Ubuntu)
- Security Group with:
  - Port **22** (SSH)
  - Port **30080** (API)
  - Port **32000** (Grafana)
- User‑data script to install MicroK8s

### Deploy infrastructure:

```bash
cd infra
terraform init
terraform apply
```

---

# 🐳 Containerization (Docker)

The API is packaged into a Docker image and pushed to **Docker Hub**.

### Build locally:

```bash
docker build -t debloxie/hello-api:latest .
```

### Push manually (optional):

```bash
docker push debloxie/hello-api:latest
```

---

# 🔄 CI Pipeline (GitHub Actions)

Every push to `main` triggers:

1. Build Docker image  
2. Push to Docker Hub  

Workflow file: `.github/workflows/ci.yml`

Key steps:

```yaml
- name: Log in to Docker Hub
  uses: docker/login-action@v3

- name: Build and push image
  run: |
    IMAGE="docker.io/${{ secrets.DOCKERHUB_USERNAME }}/hello-api:latest"
    docker build -t $IMAGE .
    docker push $IMAGE
```

Secrets required:

- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN`

---

# 🚀 CD Deployment (Manual Rolling Update)

After CI pushes a new image, deploy it to MicroK8s:

```bash
microk8s kubectl set image deployment/hello-api \
  hello-api=docker.io/debloxie/hello-api:latest \
  -n default
```

Kubernetes performs a **zero‑downtime rolling update**.

Your API remains available at:

```
http://44.199.204.3:30080/
```

---

# ☸️ Kubernetes Manifests

### Deployment (`k8s/deployment.yaml`)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-api
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: hello-api
  template:
    metadata:
      labels:
        app: hello-api
    spec:
      containers:
      - name: hello-api
        image: docker.io/debloxie/hello-api:latest
        ports:
        - containerPort: 5000
```

### Service (`k8s/service.yaml`)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: hello-api-nodeport
spec:
  type: NodePort
  selector:
    app: hello-api
  ports:
    - port: 5000
      targetPort: 5000
      nodePort: 30080
```

---

# 📊 Monitoring Stack (Prometheus + Grafana)

Installed using Helm:

```bash
microk8s helm3 repo add prometheus-community https://prometheus-community.github.io/helm-charts
microk8s helm3 repo update

microk8s helm3 install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  -n monitoring --create-namespace
```

### Prometheus Data Source in Grafana

```
http://kube-prometheus-stack-prometheus.monitoring.svc.cluster.local:9090
```

### Custom Dashboard Panels

- CPU usage  
- Memory usage  
- Pod restarts  
- Pod status  
- Optional: API latency (if metrics endpoint added)

All consolidated into:

**MicroK8s – Cluster Overview**

### Read‑Only Grafana Access

A guest account is available for safe dashboard viewing:

```
Username: guest
Password: guest
Role: Viewer
```

---

# 🎯 Key Features

- Fully containerized Python API  
- Kubernetes deployment on MicroK8s  
- Public API endpoint  
- Public Grafana dashboard with guest access  
- CI pipeline with Docker Hub  
- Terraform‑managed infrastructure  
- Prometheus metrics + Grafana dashboards  
- Clean, production‑style repo structure  

---


