# Disaster Recovery

## Objectives
| Tier | RPO | RTO |
|------|-----|-----|
| Database (RDS) | ≤ 5 min (PITR) | ≤ 30 min |
| Stateless services | 0 (redeploy from GHCR) | ≤ 10 min |
| Whole region | ≤ 15 min | ≤ 2 h |

## Backups
- **RDS**: automated daily snapshots + 7-day PITR (`backup_retention_period`).
- **Terraform state**: versioned, encrypted S3 (+ DynamoDB lock).
- **Config/manifests**: Git is the source of truth (GitOps).

## Restore (tested locally)
`pg_dump -F c` → simulate loss (`DROP TABLE`) → `pg_restore` → data recovered.
See `evidence/backup-restore-and-chaos.txt`.

## Recovery order (region failure)
1. Provision infra in DR region (`terraform apply` with DR backend).
2. Restore RDS from snapshot / cross-region replica.
3. Argo CD syncs workloads from Git.
4. Shift DNS (Route 53) to the DR ALB.

## Honesty note
Only the **local backup/restore** was executed here. Multi-region AWS failover
is **designed, not performed** (no AWS access in this environment).
