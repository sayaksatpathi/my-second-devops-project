# Runbook: Disk Full

**Related alert(s):** `DiskPressure`, `PVCAlmostFull`

## Symptoms
- Node DiskPressure; writes failing; PVC near capacity.

## Diagnose
- `kubectl describe node`; find large PVCs/logs; check log rotation and retention.

## Mitigate (stop the bleeding)
- Expand the PVC/volume; clear old logs/artifacts; evict non-critical pods.

## Resolve & verify
- Confirm the signal returns to baseline on the Grafana dashboard.
- Confirm the alert clears in Alertmanager.

## Prevent (follow-up)
- Set retention + rotation; alert at 75%/90%; storage lifecycle policies.

> Template: keep runbooks short, ordered, and action-first. After any
> user-impacting incident, write a postmortem (see `../postmortem-template.md`).
