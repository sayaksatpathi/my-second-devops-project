"""OpsForge Worker — Kafka consumer for order events.

Consumes `orders`, processes each event, and on repeated failure routes the
message to a dead-letter topic (`orders.DLQ`). Exposes Prometheus metrics on
:9100. Degrades to an idle heartbeat if Kafka is unavailable.
"""
import json
import logging
import os
import sys
import time

from prometheus_client import Counter, Gauge, start_http_server

logging.basicConfig(level=os.environ.get("LOG_LEVEL", "INFO"), stream=sys.stdout)
log = logging.getLogger("worker")

KAFKA = os.environ.get("KAFKA_BOOTSTRAP")
TOPIC = os.environ.get("KAFKA_TOPIC", "orders")
DLQ = f"{TOPIC}.DLQ"
GROUP = os.environ.get("KAFKA_GROUP", "opsforge-workers")
MAX_RETRIES = int(os.environ.get("MAX_RETRIES", "3"))

PROCESSED = Counter("worker_messages_processed_total", "Messages processed.")
FAILED = Counter("worker_messages_failed_total", "Messages sent to DLQ.")
INFLIGHT = Gauge("worker_inflight", "Messages currently being processed.")


def process(event: dict) -> None:
    """Business logic. Raises to trigger retry/DLQ (simulated failure hook)."""
    if event.get("order", {}).get("item") == "__fail__":
        raise RuntimeError("simulated processing failure")
    log.info("processed order id=%s", event.get("order", {}).get("id"))


def run() -> None:
    start_http_server(9100)
    try:
        from kafka import KafkaConsumer, KafkaProducer
    except Exception as exc:
        log.error("kafka libs missing: %s", exc)
        _idle()
        return
    if not KAFKA:
        log.warning("no KAFKA_BOOTSTRAP set; idling")
        _idle()
        return

    consumer = KafkaConsumer(
        TOPIC, bootstrap_servers=KAFKA, group_id=GROUP,
        enable_auto_commit=True, auto_offset_reset="earliest",
        value_deserializer=lambda b: json.loads(b.decode()),
    )
    producer = KafkaProducer(bootstrap_servers=KAFKA,
                             value_serializer=lambda v: json.dumps(v).encode())
    log.info("worker consuming topic=%s group=%s", TOPIC, GROUP)

    for msg in consumer:
        INFLIGHT.inc()
        event = msg.value
        for attempt in range(1, MAX_RETRIES + 1):
            try:
                process(event)
                PROCESSED.inc()
                break
            except Exception as exc:
                log.warning("process failed attempt=%d: %s", attempt, exc)
                if attempt == MAX_RETRIES:
                    producer.send(DLQ, {"original": event, "error": str(exc)})
                    producer.flush()
                    FAILED.inc()
                    log.error("message routed to DLQ=%s", DLQ)
                else:
                    time.sleep(0.2 * attempt)
        INFLIGHT.dec()


def _idle() -> None:
    while True:
        log.info("worker heartbeat (idle)")
        time.sleep(10)


if __name__ == "__main__":
    run()
