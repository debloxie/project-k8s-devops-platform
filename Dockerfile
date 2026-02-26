FROM python:3.10-slim

WORKDIR /app

COPY app.py .

RUN pip install flask prometheus_client prometheus-flask-exporter

EXPOSE 5000

CMD ["python", "app.py"]
