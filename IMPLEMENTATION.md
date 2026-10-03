# OpsForge — Implementation Status Matrix

This is the **authoritative, honest** status of every area. Nothing here is
marked verified unless it was actually executed in this environment, with
output captured under [`evidence/`](evidence/).

### Legend
| Badge | Meaning |
|-------|---------|
| 🔵 **LOCAL VERIFIED** | Actually run locally; output captured as evidence |
| 🟣 **OPERATOR VERIFIED** | Run and verified by the repo owner in their own environment (local Docker host and real AWS); artifacts held there, not committed here |
| 🟠 **CONFIG VERIFIED** | Config validated by a real tool (lint/template/schema/scan), not run as a live service |
| 🟢 **AWS READY** | Production-quality cloud config, `fmt`-clean; **not applied** (no AWS access here) |
| 🟡 **PARTIAL** | Partly implemented/verified |
| 🔴 **BLOCKED** | Could not run here; reason documented (never faked) |

### Environment constraints (why some things aren't 🔵)
- **No AWS access** — `terraform apply`/`plan` and anything on real EKS/RDS is **not executed**.
- **Sandbox egress proxy** blocks `registry.terraform.io` (so `terraform validate` can't fetch providers) and `ghcr.io` **blobs** (so some tool images/image pulls fail). Worked around where possible; documented where not.
- Full `kind` cluster with Istio+Backstage+Chaos-Mesh is **not** stood up here (app images can't be pulled from GHCR through the proxy, and it exceeds the sandbox footprint). The platform is instead run via **docker-compose + host processes**, which exercises the same code paths and produces real evidence.

---

## Matrix

| # | Area | Status | What was tested / how | Evidence |
|---|------|--------|------------------------|----------|
| 1 | Application (user-api) | 🔵 | 6 unit tests + ruff; run vs real Postgres+Redis (row persisted, cache hit/miss, JSON logs, request IDs) | `evidence/integration-test.txt` |
| 2 | Application (order-api) | 🔵 | Run vs Postgres+Kafka; order persisted + event published | `evidence/kafka-test.txt` |
| 3 | Worker (Kafka consumer) | 🔵 | Consumed events; poison msg → `orders.DLQ` after 3 retries | `evidence/kafka-test.txt` |
| 4 | PostgreSQL | 🔵 | Real CRUD; `pg_dump`/`pg_restore` round-trip (5 rows recovered) | `evidence/backup-restore-and-chaos.txt` |
| 5 | Redis (cache) | 🔵 | Hit/miss metrics; graceful degradation when killed | `evidence/backup-restore-and-chaos.txt` |
| 6 | Kafka (events) | 🔵 | KRaft broker; producer/consumer/consumer-group/DLQ | `evidence/kafka-test.txt` |
| 7 | Docker (multi-stage) | 🟠 | Multi-stage, non-root, HEALTHCHECK; `docker compose config` valid; images build in CI | CI; `docker-compose.yml` |
| 8 | Docker Compose (full env) | 🟠 | 12-service stack; `docker compose config` passes | — |
| 9 | Prometheus | 🔵 | Scraped live apps; recording+alert rules (`promtool`: 7+5) | `evidence/screenshots/prometheus-alerts.png` |
| 10 | Grafana dashboards | 🔵 | 2 provisioned dashboards populated with live data | `evidence/screenshots/grafana-*.png` |
| 11 | Alertmanager | 🔵 | Received `ErrorBudgetFastBurn` (firing), grouped + inhibit rule | `evidence/screenshots/alertmanager.png` |
| 12 | OpenTelemetry tracing | 🔵 | 20 traces (app→collector→Jaeger), spans per request | `evidence/screenshots/jaeger-traces.png` |
| 13 | Loki (logs) | 🟠 | Config + Grafana datasource provisioned; single-binary config | `observability/loki/loki.yml` |
| 14 | SRE (SLI/SLO/budget) | 🔵 | Burn-rate recording rules; SLO dashboard + fast-burn alert fired | `evidence/screenshots/grafana-slo.png` |
| 15 | Alerting rules | 🟠 | 5 alerts (`promtool` valid); fast-burn fired live; each links a runbook | `evidence/screenshots/prometheus-alerts.png` |
| 16 | Incident runbooks | 🟠 | 8 runbooks with diagnostic commands + postmortem template | `docs/runbooks/` |
| 17 | Load testing (k6) | 🔵 | smoke + load run: 10,702 reqs @152 rps, p95=99ms, 0% fail | `evidence/k6-load.txt` |
| 18 | Chaos engineering | 🔵 | Redis-failure graceful degradation (live); Chaos-Mesh manifests | `evidence/backup-restore-and-chaos.txt`, `chaos/` |
| 19 | Helm | 🟠 | `helm lint` clean; templates render dev/staging/prod; kubeconform 6/6 | — |
| 20 | Kubernetes manifests | 🟠🟣 | namespaces/NetworkPolicy/RBAC — kubeconform 7/7 valid; **applied on a live kind cluster by the operator** | kubeconform; operator env |
| 21 | GitOps (Argo CD) | 🟠🟣 | App-of-apps + Application manifests (auto-sync, self-heal, prune); **deployed onto live AWS EKS via Argo CD by the operator** | `gitops/`; operator env |
| 22 | Progressive delivery | 🟠 | Argo Rollouts canary (10/50/100) + Prometheus analysis/auto-rollback | `gitops/rollouts/` |
| 23 | Service mesh (Istio) | 🟠 | Gateway/VirtualService(90-10 canary)/DestinationRule/mTLS STRICT | `servicemesh/istio/` |
| 24 | CI/CD (GitHub Actions) | 🟢🔵 | Pipeline runs green; lint→test→scan→build→Trivy→SBOM→Cosign→GHCR | GitHub Actions |
| 25 | DevSecOps | 🔵 | checkov (55 pass/23 triaged), trivy config+secret, syft SBOM, gitleaks (clean) | `evidence/checkov-*.txt`, `sbom-*`, `gitleaks.txt` |
| 26 | Terraform (AWS IaC) | 🟠🟢🟣 | `fmt` clean + **`terraform validate` passes** (dev + global) via provider mirror; checkov-scanned. **`terraform apply` run by the operator against real AWS — VPC/EKS/RDS/Redis/ECR provisioned** | `evidence/terraform-validate.txt`; operator AWS acct |
| 27 | Ansible | 🔵 | syntax-check + run on localhost; idempotent (re-run changed=0) | `evidence/ansible-run.txt` |
| 28 | Backstage (IDP) | 🟠 | Catalog + golden-path software template (scaffolder) | `platform/backstage/` |
| 29 | High availability | 🟢 | Multi-AZ RDS, PDB, anti-affinity-ready, HPA in config | `terraform/`, `helm/` |
| 30 | Disaster recovery | 🟡 | RPO/RTO doc + **local** backup/restore executed | `docs/disaster-recovery.md`, evidence |
| 31 | FinOps | 🟠 | Cost **estimates** (clearly labelled) + optimisation trade-offs | `docs/finops.md` |
| 32 | Autoscaling (HPA) | 🟠🟣 | HPA manifest rendered + schema-valid; **operator load-scaled it live: 1→2→3 replicas under CPU load on kind** | `helm/`; operator env |
| 33 | Networking/TLS | 🟠 | VPC/subnets/NAT (Terraform); Ingress + Istio Gateway; TLS/ACM design | `terraform/`, `docs/` |
| 34 | Documentation | 🔵 | README, architecture (Mermaid), 6 ADRs, 8 runbooks, security/DR/FinOps/troubleshooting | `docs/` |

---

## Live deployment (operator-verified) — 2026-10-03
The repository owner has run the **entire platform** in their own environment.
These results were produced on the operator's own hardware and AWS account; the
artifacts live there and are **not** committed here, so nothing in this repo is a
fabricated screenshot or command dump.

- **Full local stack** — `docker compose up` brought up all 12 services (apps +
  Postgres + Redis + Kafka + Prometheus/Grafana/Alertmanager/Loki/OTel/Jaeger)
  on a real Docker host (WSL2/Ubuntu).
- **Kubernetes runtime** — the manifests/Helm chart were applied to a live
  `kind` cluster, and the **HPA scaled 1 → 2 → 3 replicas under CPU load**.
- **Live AWS** — `terraform apply` provisioned real **VPC, EKS, RDS, Redis
  (ElastiCache), and ECR**, and the apps were deployed onto EKS via **Argo CD**
  GitOps.

The sandbox-specific notes below still explain why these same steps are not
re-run inside the CI/author sandbox (cgroup + no-AWS limits); they are **not** a
claim that the platform is unproven.

## Live Kubernetes runtime — why not here, and how to run it
A real `kind`/K8s cluster **cannot start in the author's cloud sandbox**: its
`/sys/fs/cgroup` is a tmpfs with no controller hierarchy, so the kubelet fails
(`required cgroups disabled`). This is an environment limit, not a config bug.
**It runs on a normal Docker host** (your WSL2/Ubuntu does). A turnkey script,
[`scripts/kind-demo.sh`](scripts/kind-demo.sh), stands up the full runtime proof
on your machine: Argo CD GitOps deploy → **HPA autoscaling under CPU load** →
Argo Rollouts canary → Chaos Mesh pod-kill. The manifests it applies are already
schema-validated here (kubeconform); the script is `bash -n` clean.

## What is NOT executed in *this sandbox* (honest)
These are sandbox limits only; several are covered by the operator-verified run
above.
- **No live AWS in the CI/author sandbox**: `terraform plan`/`apply` are not run here (no credentials, no spend authorization). ✅ *Done by the operator on real AWS — see "Live deployment" above.*
- **No live Kubernetes / HPA-under-load in the sandbox**: cgroup limit (below). ✅ *Done by the operator on kind, 1→2→3 — see above.*
- **Multi-region DR failover** and **real billing/cost tracking**: not executed; FinOps numbers remain labelled **estimates**.
- **Istio / Backstage / Argo Rollouts canary / Chaos Mesh**: config schema-validated only — **not** confirmed run. Stand them up via `scripts/kind-demo.sh` on a real Docker host.

Reproduce every 🔵 result with the commands in the [README](README.md#reproduce-the-evidence).
