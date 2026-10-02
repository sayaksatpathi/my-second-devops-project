"""OpsForge User API — a small FastAPI service, instrumented for observability.

Endpoints:
  GET  /           - service info
  GET  /health     - liveness/readiness probe
  GET  /users      - list users (in-memory demo store)
  POST /users      - create a user
  GET  /metrics    - Prometheus metrics (RED method)

The app is intentionally simple; the platform around it is the project.
"""
import os
import time

from fastapi import FastAPI, Response
from pydantic import BaseModel
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Histogram, generate_latest

app = FastAPI(title="OpsForge User API", version="0.1.0")

REQUEST_COUNT = Counter(
    "http_requests_total", "Total HTTP requests.",
    ["method", "endpoint", "http_status"],
)
REQUEST_LATENCY = Histogram(
    "http_request_duration_seconds", "HTTP request latency.",
    ["method", "endpoint"],
)

_users: list[dict] = []


class User(BaseModel):
    name: str
    email: str


@app.middleware("http")
async def record_metrics(request, call_next):
    start = time.perf_counter()
    response = await call_next(request)
    endpoint = request.url.path
    if endpoint != "/metrics":
        REQUEST_LATENCY.labels(request.method, endpoint).observe(time.perf_counter() - start)
        REQUEST_COUNT.labels(request.method, endpoint, response.status_code).inc()
    return response


@app.get("/")
def index():
    return {"service": "user-api", "status": "ok"}


@app.get("/health")
def health():
    return {"status": "healthy"}


@app.get("/users")
def list_users():
    return {"users": _users, "count": len(_users)}


@app.post("/users", status_code=201)
def create_user(user: User):
    record = {"id": len(_users) + 1, **user.model_dump()}
    _users.append(record)
    return record


@app.get("/metrics")
def metrics():
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=int(os.environ.get("PORT", "8000")))
