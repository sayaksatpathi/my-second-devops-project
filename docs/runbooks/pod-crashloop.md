# Runbook: Pod CrashLoopBackOff

**Related alert(s):** `PodCrashLooping`

## Symptoms
- Pod restarts repeatedly; readiness never passes.

## Diagnose
- `kubectl logs --previous`; `kubectl describe pod`; check config/secret mounts, failing migrations, bad image.

## Mitigate (stop the bleeding)
- Roll back to last-good image via GitOps; fix the config/secret; pause rollout.

## Resolve & verify
- Confirm the signal returns to baseline on the Grafana dashboard.
- Confirm the alert clears in Alertmanager.

## Prevent (follow-up)
- Add readiness/liveness probes; validate config in CI; canary deploys.

> Template: keep runbooks short, ordered, and action-first. After any
> user-impacting incident, write a postmortem (see `../postmortem-template.md`).
