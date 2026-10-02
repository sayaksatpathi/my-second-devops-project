# Troubleshooting Guide

| Symptom | First checks | Likely fix |
|---------|-------------|-----------|
| Pod `CrashLoopBackOff` | `kubectl logs --previous`, `describe pod` | bad config/secret, failing migration → roll back image |
| `/ready` 503 | which dep is false in the JSON body | DB down / SG / pool exhausted |
| High latency / SLO burn | SLO dashboard + Jaeger traces | scale bottleneck, cache, roll back regression |
| 5xx spike after deploy | compare to last green image tag | roll back via GitOps |
| Kafka messages stuck | consumer lag, DLQ topic | check worker logs; replay DLQ |
| Image won't pull | registry auth / signature verify | re-login; check Cosign policy |
| Terraform drift | `terraform plan` | reconcile or import |

See `docs/runbooks/` for alert-specific procedures.
