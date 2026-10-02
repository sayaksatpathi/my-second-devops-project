#!/usr/bin/env bash
# Verify the event-driven path: order-api -> Kafka -> worker, incl. DLQ.
# Local containers only (zero AWS cost).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

docker rm -f it-kafka it-pg2 >/dev/null 2>&1 || true

echo "==> starting kafka (KRaft) + postgres"
docker run -d --name it-pg2 -e POSTGRES_USER=opsforge -e POSTGRES_PASSWORD=opsforge \
  -e POSTGRES_DB=opsforge -p 5433:5432 postgres:16-alpine >/dev/null
docker run -d --name it-kafka -p 9092:9092 \
  -e KAFKA_NODE_ID=1 -e KAFKA_PROCESS_ROLES=broker,controller \
  -e KAFKA_LISTENERS=PLAINTEXT://:9092,CONTROLLER://:9093 \
  -e KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://localhost:9092 \
  -e KAFKA_CONTROLLER_LISTENER_NAMES=CONTROLLER \
  -e KAFKA_LISTENER_SECURITY_PROTOCOL_MAP=CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT \
  -e KAFKA_CONTROLLER_QUORUM_VOTERS=1@localhost:9093 \
  -e KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=1 \
  -e KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS=0 \
  -e KAFKA_AUTO_CREATE_TOPICS_ENABLE=true \
  apache/kafka:3.8.0 >/dev/null

echo "==> waiting for kafka"
for i in $(seq 1 40); do
  docker exec it-kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server localhost:9092 --list >/dev/null 2>&1 && break || sleep 2
done

export DATABASE_URL="postgresql+psycopg2://opsforge:opsforge@localhost:5433/opsforge"
export KAFKA_BOOTSTRAP="localhost:9092"
export KAFKA_TOPIC="orders"

echo "==> starting order-api"
( cd "$ROOT/app/order-api" && PYTHONPATH=. uvicorn app.main:app --host 0.0.0.0 --port 8001 ) &
OAPI=$!
for i in $(seq 1 20); do curl -fs localhost:8001/health >/dev/null 2>&1 && break || sleep 1; done
curl -s localhost:8001/ready; echo

echo "==> POST a normal order and a poison order (item=__fail__)"
curl -s -XPOST localhost:8001/orders -H 'content-type: application/json' -d '{"user_id":1,"item":"widget","qty":2}'; echo
curl -s -XPOST localhost:8001/orders -H 'content-type: application/json' -d '{"user_id":1,"item":"__fail__","qty":1}'; echo

echo "==> starting worker for 15s to consume"
( cd "$ROOT/app/worker" && timeout 15 python worker.py ) || true

echo "==> topics (expect orders, orders.DLQ)"
docker exec it-kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server localhost:9092 --list | grep -E "orders" || true

echo "==> DLQ contents (the poison message)"
docker exec it-kafka /opt/kafka/bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 \
  --topic orders.DLQ --from-beginning --timeout-ms 4000 2>/dev/null || true

kill $OAPI 2>/dev/null || true
echo "==> kafka test complete"
