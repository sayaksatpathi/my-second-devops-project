# Runbook: Database Unavailable (RDS)

**Related alert(s):** `PostgresDown`, connection errors

## Symptoms
- 5xx spikes; app logs show connection refused/timeouts to PostgreSQL.

## Diagnose
- Check RDS status (console/CloudWatch); verify security groups, connection pool exhaustion, and failover state (Multi-AZ).

## Mitigate (stop the bleeding)
- Fail over to standby if not automatic; enable graceful degradation / cache-only mode; shed load.

## Resolve & verify
- Confirm the signal returns to baseline on the Grafana dashboard.
- Confirm the alert clears in Alertmanager.

## Prevent (follow-up)
- Multi-AZ + read replicas; connection pooling (PgBouncer); circuit breakers in the app.

> Template: keep runbooks short, ordered, and action-first. After any
> user-impacting incident, write a postmortem (see `../postmortem-template.md`).
