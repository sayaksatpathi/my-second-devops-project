#!/usr/bin/env bash
# Integration test: run user-api against real Postgres + Redis and verify
# persistence and cache hit/miss behaviour. Zero AWS cost (local containers).
set -euo pipefail

NET=opsforge-it
docker network create $NET >/dev/null 2>&1 || true
docker rm -f it-pg it-redis >/dev/null 2>&1 || true

echo "==> starting postgres + redis"
docker run -d --name it-pg --network $NET \
  -e POSTGRES_USER=opsforge -e POSTGRES_PASSWORD=opsforge -e POSTGRES_DB=opsforge \
  -p 5432:5432 postgres:16-alpine >/dev/null
docker run -d --name it-redis --network $NET -p 6379:6379 redis:7-alpine >/dev/null

echo "==> waiting for postgres"
for i in $(seq 1 30); do
  docker exec it-pg pg_isready -U opsforge >/dev/null 2>&1 && break || sleep 1
done

export DATABASE_URL="postgresql+psycopg2://opsforge:opsforge@localhost:5432/opsforge"
export REDIS_URL="redis://localhost:6379/0"

echo "==> starting user-api"
( cd "$(dirname "$0")/../app/user-api" && PYTHONPATH=. uvicorn app.main:app --host 0.0.0.0 --port 8000 ) &
APP_PID=$!
for i in $(seq 1 20); do curl -fs localhost:8000/health >/dev/null 2>&1 && break || sleep 1; done

echo "==> readiness (expect database:true, cache:true)"
curl -s localhost:8000/ready; echo
echo "==> create user (persisted to postgres)"
UID_=$(curl -s -XPOST localhost:8000/users -H 'content-type: application/json' \
  -d '{"name":"Ada","email":"ada@example.com"}' | python3 -c "import sys,json;print(json.load(sys.stdin)['id'])")
echo "created id=$UID_"
echo "==> first GET (cache MISS)"; curl -s localhost:8000/users/$UID_; echo
echo "==> second GET (cache HIT)"; curl -s localhost:8000/users/$UID_; echo
echo "==> verify row exists directly in postgres"
docker exec it-pg psql -U opsforge -d opsforge -tAc "SELECT name,email FROM users WHERE id=$UID_;"
echo "==> cache metrics"
curl -s localhost:8000/metrics | grep -E "^cache_(hits|misses)_total"

kill $APP_PID 2>/dev/null || true
echo "==> integration test complete"
