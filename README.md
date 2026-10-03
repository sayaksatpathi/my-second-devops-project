# 🚀 Project 2 — OpsForge

**Cloud-Native DevSecOps & SRE Platform**

[![CI/CD](https://github.com/sayaksatpathi/opsforge-platform/actions/workflows/ci.yml/badge.svg)](https://github.com/sayaksatpathi/opsforge-platform/actions/workflows/ci.yml)
![Python](https://img.shields.io/badge/Python-3.12-3776AB?logo=python&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-Helm%20%2B%20ArgoCD-326CE5?logo=kubernetes&logoColor=white)
![IaC](https://img.shields.io/badge/IaC-Terraform-7B42BC?logo=terraform&logoColor=white)
![Observability](https://img.shields.io/badge/Observability-Prometheus%20%7C%20Grafana%20%7C%20Loki%20%7C%20OTel-E6522C?logo=prometheus&logoColor=white)
![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)

A production-style platform where a developer pushes code and the system
**tests → secures → builds → signs → deploys (GitOps) → observes** it on
Kubernetes, with SLOs, burn-rate alerting, distributed tracing, chaos
experiments, load testing, and incident tooling.

> **Honesty first.** This repo is built and **actually run** where the
> environment allows, and it says exactly what is verified vs. designed. The
> single source of truth is **[`IMPLEMENTATION.md`](IMPLEMENTATION.md)**; real
> command output and screenshots live in **[`evidence/`](evidence/)**.
> No AWS infrastructure is deployed (that costs real money and this environment
> has no AWS access) — the Terraform is production-quality and `fmt`-clean, and
> everything runnable is proven locally at zero cost.

## What's actually verified (🔵 = run here, with evidence)

- 🔵 **App platform** — user-api/order-api/worker on **Postgres + Redis + Kafka**; persistence, caching, consumer-group + **DLQ** all confirmed.
- 🔵 **Observability** — Prometheus dashboards, **SLO/error-budget**, a **firing burn-rate alert** in Alertmanager, and **20 distributed traces** in Jaeger (OTel).
- 🔵 **Load test** — k6: 10,702 reqs @ 152 rps, **p95 = 99 ms, 0% errors**.
- 🔵 **Resilience** — Postgres backup/restore round-trip; **Redis-failure graceful degradation**.
- 🔵 **Ansible** — playbook runs on localhost and is **idempotent**.
- 🔵 **DevSecOps** — checkov, trivy, syft (SBOM), gitleaks (no leaks); CI signs images with Cosign.
- 🟠 **Config-validated** — Helm (`lint`+`template`+kubeconform), K8s (kubeconform), Argo CD, Istio, Argo Rollouts, Backstage.
- 🟢 **AWS-ready** — Terraform modules (VPC/EKS/RDS/Redis/ECR/IAM-OIDC), `fmt`-clean, **not applied**.

See the full matrix in [`IMPLEMENTATION.md`](IMPLEMENTATION.md).

## Architecture

Full diagrams (delivery pipeline, runtime/observability, infra) in
[`docs/architecture.md`](docs/architecture.md).

```text
push → GitHub Actions (lint→test→SAST→build→Trivy→SBOM→Cosign) → GHCR
     → GitOps (Argo CD) → Kubernetes → Prometheus/Grafana/Loki/OTel
     → SLOs → burn-rate alerts → runbooks
```

## Repository layout

| Path | Area | Status |
|------|------|--------|
| `app/` | FastAPI services (user/order/worker) + tests | 🔵 verified |
| `docker-compose.yml` | Full local env (apps + data + observability) | 🟠 config-valid |
| `terraform/` | AWS IaC (VPC, EKS, RDS, Redis, ECR, IAM/OIDC) | 🟢 AWS-ready |
| `ansible/` | Node/config management (role + playbook) | 🔵 verified |
| `helm/` | App chart (securityContext, PDB, HPA, env values) | 🟠 lint+template+kubeconform |
| `k8s/` | Namespaces, NetworkPolicy, RBAC | 🟠 kubeconform |
| `gitops/` | Argo CD app-of-apps + Argo Rollouts canary | 🟠 config-valid |
| `servicemesh/istio/` | Gateway/VirtualService/mTLS/canary | 🟠 config-valid |
| `observability/` | Prometheus/Grafana/Loki/OTel/Alertmanager | 🔵 verified |
| `security/` + CI | Trivy/SBOM/Cosign/checkov/gitleaks | 🔵 verified |
| `chaos/`, `load/` | Chaos Mesh + k6 | 🔵 verified |
| `platform/backstage/` | IDP catalog + golden-path template | 🟠 config-valid |
| `docs/` | Architecture, ADRs, 8 runbooks, security/DR/FinOps/troubleshooting | ✅ |
| `evidence/` | Real captured output + screenshots | ✅ |

## Quick start (local, free)

```bash
# Unit tests
cd app/user-api && pip install -r requirements-dev.txt && pytest -q && cd -

# Full stack (apps + Postgres/Redis/Kafka + Prometheus/Grafana/Jaeger/...)
docker compose up --build
#  Grafana   http://localhost:3000 (admin/admin)
#  Prometheus http://localhost:9090   ·  Alertmanager http://localhost:9093
#  Jaeger    http://localhost:16686
```

## Reproduce the evidence

Each 🔵 result is reproducible with one script (needs Docker):

```bash
./scripts/integration-test.sh      # user-api + Postgres + Redis
./scripts/kafka-test.sh            # order-api → Kafka → worker (+ DLQ)
cd ansible && ansible-playbook playbooks/site.yml   # idempotent config mgmt
docker run --rm -i -e TARGET=http://host.docker.internal:8000 \
  --add-host=host.docker.internal:host-gateway grafana/k6 run - < load/load.js
```

Observability screenshots (dashboards, firing alert, traces) were captured
from the running stack and live in [`evidence/screenshots/`](evidence/screenshots/).

## Validate the config

```bash
helm lint helm/opsforge && helm template opsforge helm/opsforge >/dev/null
terraform -chdir=terraform fmt -check -recursive
docker run --rm -v "$PWD/terraform:/tf:ro" bridgecrew/checkov -d /tf   # IaC scan
```

## License

[MIT](LICENSE) © 2026 Sayak Satpathi
