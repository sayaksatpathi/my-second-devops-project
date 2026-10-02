"""OpsForge User API.

Production-style FastAPI service: PostgreSQL persistence (in-memory fallback),
Redis caching with graceful degradation, Prometheus metrics (RED + cache),
structured JSON logging with request IDs, optional OpenTelemetry tracing, and
liveness/readiness probes.
"""
import logging
import time
import uuid

from fastapi import FastAPI, HTTPException, Request, Response
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Gauge, Histogram, generate_latest
from pydantic import BaseModel, EmailStr

from .cache import Cache
from .config import get_settings
from .db import make_store
from .logging_config import configure_logging, request_id_var
from .telemetry import init_tracing

settings = get_settings()
configure_logging(settings.log_level)
logger = logging.getLogger("user-api")

REQUEST_COUNT = Counter("http_requests_total", "Total HTTP requests.",
                        ["method", "endpoint", "http_status"])
REQUEST_LATENCY = Histogram("http_request_duration_seconds", "Request latency.",
                            ["method", "endpoint"])
IN_PROGRESS = Gauge("http_requests_in_progress", "In-flight requests.", ["endpoint"])

app = FastAPI(title="OpsForge User API", version="1.0.0")
store = make_store(settings.database_url)
cache = Cache(settings.redis_url, settings.cache_ttl_seconds)
init_tracing(app, settings.service_name, settings.otel_exporter_otlp_endpoint)


class UserIn(BaseModel):
    name: str
    email: EmailStr


@app.middleware("http")
async def observability_mw(request: Request, call_next):
    rid = request.headers.get("x-request-id", str(uuid.uuid4()))
    request_id_var.set(rid)
    endpoint = request.url.path
    IN_PROGRESS.labels(endpoint).inc()
    start = time.perf_counter()
    try:
        response = await call_next(request)
    finally:
        IN_PROGRESS.labels(endpoint).dec()
    if endpoint != "/metrics":
        REQUEST_LATENCY.labels(request.method, endpoint).observe(time.perf_counter() - start)
        REQUEST_COUNT.labels(request.method, endpoint, response.status_code).inc()
    response.headers["x-request-id"] = rid
    return response


@app.get("/")
def index():
    return {"service": settings.service_name, "status": "ok"}


@app.get("/health")
def health():
    """Liveness: process is up."""
    return {"status": "healthy"}


@app.get("/ready")
def ready():
    """Readiness: dependencies reachable (DB required, cache optional)."""
    db_ok = store.ping()
    status = {"database": db_ok, "cache": cache.ping() if cache.enabled else "disabled"}
    if not db_ok:
        raise HTTPException(status_code=503, detail=status)
    return {"status": "ready", **status}


@app.get("/users")
def list_users():
    return {"users": store.list(), "count": len(store.list())}


@app.post("/users", status_code=201)
def create_user(user: UserIn):
    rec = store.create(user.name, str(user.email))
    cache.set_user(rec)
    logger.info("user created", extra={"extra_fields": {"user_id": rec["id"]}})
    return rec


@app.get("/users/{user_id}")
def get_user(user_id: int):
    cached = cache.get_user(user_id)
    if cached:
        return {**cached, "_cache": "hit"}
    rec = store.get(user_id)
    if not rec:
        raise HTTPException(status_code=404, detail="user not found")
    cache.set_user(rec)
    return {**rec, "_cache": "miss"}


@app.get("/work")
def work(fail_rate: float = 0.0, max_ms: int = 0, burn_ms: int = 0):
    """Fault-injection endpoint for load tests, chaos, and autoscaling demos.
    ?fail_rate=0.1 -> ~10% return HTTP 500
    ?max_ms=500    -> up to 500ms of (idle) latency
    ?burn_ms=50    -> busy-loop ~50ms of CPU (drives HPA scale-up)
    """
    import random

    if burn_ms:
        deadline = time.perf_counter() + min(burn_ms, 1000) / 1000.0
        while time.perf_counter() < deadline:
            pass
    if max_ms:
        time.sleep(random.uniform(0, max_ms) / 1000.0)
    if random.random() < fail_rate:
        raise HTTPException(status_code=500, detail="injected failure")
    return {"status": "done"}


@app.get("/metrics")
def metrics():
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)
