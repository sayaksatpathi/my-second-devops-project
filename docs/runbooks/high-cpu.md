# Runbook: High CPU

**Related alert(s):** `HighCpuUsage`, HPA saturation

## Symptoms
- Latency rising; HPA at max replicas; CPU throttling in pod metrics.

## Diagnose
- `kubectl top pods -n <ns>`; check the Kubernetes + App Grafana dashboards; look for a hot endpoint or a deploy that changed CPU profile.

## Mitigate (stop the bleeding)
- Scale the deployment (or raise HPA max); if a bad deploy, roll back the image tag via GitOps.

## Resolve & verify
- Confirm the signal returns to baseline on the Grafana dashboard.
- Confirm the alert clears in Alertmanager.

## Prevent (follow-up)
- Right-size requests/limits; add load tests for the hot path; consider caching.

> Template: keep runbooks short, ordered, and action-first. After any
> user-impacting incident, write a postmortem (see `../postmortem-template.md`).
