
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


- **Flask API Deployment**  
  - Exposes `/`, `/health`, and `/metrics`  
  - Metrics exported via `prometheus_flask_exporter`

- **Prometheus Operator**  
  Installed via Helm:
  ```
  helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
  helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack -n monitoring --create-namespace
  ```

- **Grafana**  
  - Exposed via NodePort  
  - Includes custom dashboards for API metrics

---

## Public Endpoints
Replace `<EC2_PUBLIC_IP>` with your instance IP.

| Component | URL |
|----------|-----|
| **API Root** | `http://44.199.204.3:30080/` |
| **API Health Check** | `http://44.199.204.3:30080/health` |
| **API Metrics** | `http://44.199.204.3:30080/metrics` |
| **Grafana Dashboard** | `http://44.199.204.3:32000/` |

### Optional Read‑Only Grafana User
```
Username: guest
Password: guest
```

---

## Directory Structure
```
k8s/
│
├── deployment.yaml
├── service-nodeport.yaml
├── service-clusterip.yaml
├── servicemonitor.yaml
└── dashboards/
    └── hello-api-dashboard.json
```

---

## Flask API + Metrics Exporter

### app.py
```python
from flask import Flask
from prometheus_flask_exporter import PrometheusMetrics

app = Flask(__name__)
metrics = PrometheusMetrics(app)

@app.route("/")
def index():
    return {"message": "Hello from Kubernetes!"}

@app.route("/health")
def health():
    return {"status": "ok"}

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
```

### Metrics exposed
The exporter automatically provides:

- `flask_http_request_total`
- `flask_http_request_duration_seconds`
- `flask_exporter_info`
- Default process metrics

---

## Kubernetes Manifests

### Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-api
  labels:
    app: hello-api
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
        image: debloxie/hello-api:latest
        ports:
        - containerPort: 5000
```

### NodePort Service (public)
```yaml
apiVersion: v1
kind: Service
metadata:
  name: hello-api-nodeport
  labels:
    app: hello-api
spec:
  type: NodePort
  selector:
    app: hello-api
  ports:
  - name: http
    port: 5000
    targetPort: 5000
    nodePort: 30080
```

### ClusterIP Service (Prometheus scraping)
```yaml
apiVersion: v1
kind: Service
metadata:
  name: hello-api
  labels:
    app: hello-api
    release: kube-prometheus-stack
spec:
  selector:
    app: hello-api
  ports:
  - name: http
    port: 5000
    targetPort: 5000
```

### ServiceMonitor
```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: hello-api-monitor
  namespace: monitoring
  labels:
    release: kube-prometheus-stack
spec:
  selector:
    matchLabels:
      app: hello-api
  namespaceSelector:
    matchNames:
      - default
  endpoints:
  - port: http
    path: /metrics
    interval: 15s
```

---

## Grafana Dashboard Panels

### Total Requests
```
sum(flask_http_request_total)
```

### Requests Per Second (RPS)
```
sum(rate(flask_http_request_total[1m]))
```

### Error Rate
```
sum(rate(flask_http_request_total{status!="200"}[5m]))
```

### Requests by Status Code
```
sum by (status) (flask_http_request_total)
```

### Requests by Method
```
sum by (method) (flask_http_request_total)
```

### RPS by Pod (scaling visibility)
```
sum by (pod) (rate(flask_http_request_total[1m]))
```

### 95th Percentile Latency (if histogram enabled)
```
histogram_quantile(0.95, sum(rate(flask_http_request_duration_seconds_bucket[5m])) by (le))
```

---

## Validation Steps

### 1. Confirm Prometheus target is UP
```
wget -qO- http://localhost:9090/api/v1/targets | grep hello-api -A5
```

### 2. Confirm metrics are flowing
```
wget -qO- "http://localhost:9090/api/v1/query?query=flask_http_request_total"
```

### 3. Generate traffic
```
for i in {1..20}; do curl -s http://<EC2_PUBLIC_IP>:30080/ > /dev/null; done
```

---

## What This Project Demonstrates
- Kubernetes deployment skills  
- MicroK8s cluster setup on EC2  
- Prometheus Operator integration  
- Custom ServiceMonitor configuration  
- Application‑level metrics instrumentation  
- Grafana dashboard design  
- Real‑world observability patterns  
- Production‑style API monitoring  

  

---


