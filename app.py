from flask import Flask, jsonify
from prometheus_flask_exporter import PrometheusMetrics
from prometheus_client import Counter

app = Flask(__name__)

# Automatically collects latency, request count, status codes, etc.
metrics = PrometheusMetrics(app)

# Optional: keep your custom counter
REQUEST_COUNT = Counter("hello_api_requests_total", "Total requests to Hello API")

@app.route("/")
def home():
    REQUEST_COUNT.inc()
    return jsonify({"message": "Hello from Debo's MicroK8s API!"})

@app.route("/health")
def health():
    return jsonify({"status": "healthy"})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
