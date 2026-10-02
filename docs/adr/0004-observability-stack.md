# ADR 0004: Observability stack — Prometheus, Grafana, Loki, OpenTelemetry

**Status:** Accepted

## Context
We need the three pillars of observability — metrics, logs, traces — plus
dashboards and alerting, ideally open-source and runnable locally.

## Decision
Metrics: **Prometheus**. Dashboards: **Grafana**. Logs: **Loki + Fluent Bit**.
Traces: **OpenTelemetry**. Alerting: **Alertmanager**.

## Consequences
+ Open-source, no vendor lock-in, runs locally on `kind`.
− Self-managed; in production you operate the stack yourself (or use managed).
