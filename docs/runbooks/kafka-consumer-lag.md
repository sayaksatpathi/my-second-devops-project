# Runbook: Kafka Consumer Lag / DLQ

**Alert:** `WorkerMessagesToDLQ`

## Symptoms
- `worker_messages_failed_total` increasing; messages landing in `orders.DLQ`.

## Diagnose
- `kubectl logs deploy/worker` — why is `process()` raising?
- Inspect DLQ: `kafka-console-consumer --topic orders.DLQ --from-beginning`.
- Check consumer lag (kafka-exporter metric / `kafka-consumer-groups --describe`).

## Mitigate
- If a bad deploy: roll back the worker image via GitOps.
- If a downstream dependency: fix it, then **replay** DLQ messages into `orders`.
- Scale the worker (more consumers in the group) if lag is pure throughput.

## Prevent
- Add schema validation at the producer; alert on lag thresholds; size the
  consumer group to peak throughput.
