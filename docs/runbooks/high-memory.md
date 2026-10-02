# Runbook: High Memory / OOMKilled

**Related alert(s):** `HighMemoryUsage`, `PodOOMKilled`

## Symptoms
- Pods restarting with reason OOMKilled; memory climbing then sawtooth.

## Diagnose
- `kubectl describe pod` (Last State: OOMKilled); check for a memory leak or undersized limits; review recent deploys.

## Mitigate (stop the bleeding)
- Raise memory limits; roll back a leaking release; restart affected pods.

## Resolve & verify
- Confirm the signal returns to baseline on the Grafana dashboard.
- Confirm the alert clears in Alertmanager.

## Prevent (follow-up)
- Add a memory-leak test; set sensible requests/limits; profile the service.

> Template: keep runbooks short, ordered, and action-first. After any
> user-impacting incident, write a postmortem (see `../postmortem-template.md`).
