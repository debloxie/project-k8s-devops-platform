from flask import Flask, jsonify
from prometheus_client import Counter, generate_latest

app = Flask(__name__)

REQUEST_COUNT = Counter("hello_api_requests_total", "Total requests to Hello API")

@app.route("/")
def home():
    REQUEST_COUNT.inc()
    return jsonify({"message": "Hello from Debo's MicroK8s API!"})

@app.route("/health")
def health():
    return jsonify({"status": "healthy"})

@app.route("/metrics")
def metrics():
    return generate_latest(), 200, {"Content-Type": "text/plain"}

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)

