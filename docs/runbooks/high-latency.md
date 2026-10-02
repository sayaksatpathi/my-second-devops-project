# Runbook: High Latency (SLO burn)

**Related alert(s):** `ErrorBudgetFastBurn`, p95 breach

## Symptoms
- p95/p99 latency above SLO; error budget burning fast.

## Diagnose
- Check golden-signals + traces (OpenTelemetry) to find the slow span; DB/Redis/downstream?

## Mitigate (stop the bleeding)
- Scale the bottleneck; add/fix caching; roll back a regression; raise timeouts carefully.

## Resolve & verify
- Confirm the signal returns to baseline on the Grafana dashboard.
- Confirm the alert clears in Alertmanager.

## Prevent (follow-up)
- Load-test the path; add tracing SLOs; cache hot reads.

> Template: keep runbooks short, ordered, and action-first. After any
> user-impacting incident, write a postmortem (see `../postmortem-template.md`).
