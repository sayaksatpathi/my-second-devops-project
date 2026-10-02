"""OpsForge Order API.

Creates orders in PostgreSQL, caches lookups in Redis, and publishes an
`order.created` event to Kafka. Degrades gracefully if Kafka/Redis are down.
"""
import json
import logging
import os
import sys
import time
import uuid

from fastapi import FastAPI, HTTPException, Request, Response
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Histogram, generate_latest
from pydantic import BaseModel

logging.basicConfig(level=os.environ.get("LOG_LEVEL", "INFO"), stream=sys.stdout)
log = logging.getLogger("order-api")

DATABASE_URL = os.environ.get("DATABASE_URL")
REDIS_URL = os.environ.get("REDIS_URL")
KAFKA = os.environ.get("KAFKA_BOOTSTRAP")
TOPIC = os.environ.get("KAFKA_TOPIC", "orders")

REQS = Counter("http_requests_total", "Requests.", ["method", "endpoint", "http_status"])
LAT = Histogram("http_request_duration_seconds", "Latency.", ["method", "endpoint"])
EVENTS = Counter("order_events_published_total", "Order events published to Kafka.")

app = FastAPI(title="OpsForge Order API", version="1.0.0")


# ---- lightweight backends with graceful degradation ----
def _make_engine():
    if not DATABASE_URL:
        return None
    from sqlalchemy import Column, Integer, MetaData, String, Table, create_engine
    eng = create_engine(DATABASE_URL, pool_pre_ping=True)
    md = MetaData()
    Table("orders", md,
          Column("id", Integer, primary_key=True),
          Column("user_id", Integer, nullable=False),
          Column("item", String(255), nullable=False),
          Column("qty", Integer, nullable=False))
    md.create_all(eng)
    return eng


engine = _make_engine()
_mem: list[dict] = []

try:
    import redis
    rds = redis.Redis.from_url(REDIS_URL, socket_timeout=1, decode_responses=True) if REDIS_URL else None
    if rds:
        rds.ping()
except Exception:
    rds = None

try:
    from kafka import KafkaProducer
    producer = KafkaProducer(bootstrap_servers=KAFKA,
                             value_serializer=lambda v: json.dumps(v).encode(),
                             retries=3, acks="all") if KAFKA else None
except Exception as exc:
    log.error("kafka producer init failed: %s", exc)
    producer = None


class OrderIn(BaseModel):
    user_id: int
    item: str
    qty: int = 1


@app.middleware("http")
async def mw(request: Request, call_next):
    start = time.perf_counter()
    resp = await call_next(request)
    ep = request.url.path
    if ep != "/metrics":
        LAT.labels(request.method, ep).observe(time.perf_counter() - start)
        REQS.labels(request.method, ep, resp.status_code).inc()
    return resp


@app.get("/health")
def health():
    return {"status": "healthy"}


@app.get("/ready")
def ready():
    ok = True
    if engine:
        from sqlalchemy import text
        try:
            with engine.connect() as c:
                c.execute(text("SELECT 1"))
        except Exception:
            ok = False
    if not ok:
        raise HTTPException(503, "database not ready")
    return {"status": "ready", "kafka": bool(producer), "cache": bool(rds)}


@app.post("/orders", status_code=201)
def create_order(order: OrderIn):
    rec = {"id": None, **order.model_dump()}
    if engine:
        from sqlalchemy import insert, Table, MetaData
        md = MetaData()
        t = Table("orders", md, autoload_with=engine)
        with engine.begin() as c:
            r = c.execute(insert(t).values(**order.model_dump()))
            rec["id"] = r.inserted_primary_key[0]
    else:
        rec["id"] = len(_mem) + 1
        _mem.append(rec)
    if producer:
        try:
            producer.send(TOPIC, {"event": "order.created", "order": rec, "id": str(uuid.uuid4())})
            producer.flush(timeout=5)
            EVENTS.inc()
            log.info("published order.created id=%s", rec["id"])
        except Exception as exc:
            log.error("kafka publish failed (order still saved): %s", exc)
    return rec


@app.get("/orders")
def list_orders():
    if engine:
        from sqlalchemy import select, Table, MetaData
        md = MetaData()
        t = Table("orders", md, autoload_with=engine)
        with engine.connect() as c:
            return {"orders": [dict(r) for r in c.execute(select(t)).mappings()]}
    return {"orders": _mem}


@app.get("/metrics")
def metrics():
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)
