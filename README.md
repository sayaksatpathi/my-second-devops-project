# 🚀 OpsForge — Enterprise Cloud-Native DevSecOps & SRE Platform

![Status](https://img.shields.io/badge/status-scaffold-yellow)
![IaC](https://img.shields.io/badge/IaC-Terraform-7B42BC?logo=terraform&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-EKS-326CE5?logo=kubernetes&logoColor=white)
![GitOps](https://img.shields.io/badge/GitOps-Argo%20CD-EF7B4D?logo=argo&logoColor=white)
![Observability](https://img.shields.io/badge/Observability-Prometheus%20%2B%20Grafana-E6522C?logo=prometheus&logoColor=white)
![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)

A production-style platform where a developer pushes code and the system
automatically **tests → secures → builds → signs → deploys (GitOps) →
observes** it on Kubernetes, with SLOs, alerting, chaos testing, and incident
tooling. It's the "everything, integrated" companion to the focused
[SRE Reliability Lab](https://github.com/sayaksatpathi/my-first-devops-project).

> ### ⚠️ Project status: **scaffold / work-in-progress**
> This repo is deliberately built in **phases**, and it's honest about state.
> Each area below is tagged:
> - ✅ **implemented & verified** — runs, with evidence
> - 🟡 **scaffold** — real, reviewable config/code; not yet fully wired/run
> - 📋 **planned** — directory + design notes, implementation to come
>
> **The AWS layer is written to be `validate`-clean but is _not_ applied here** —
> a live EKS/RDS/NAT platform costs real money. Everything that can run **free and
> locally on `kind`** (app, GitOps, observability, chaos, load) is the path to
> real, verifiable evidence. See [ADR 0006](docs/adr/0006-local-first-verification.md).

## Architecture

See [`docs/architecture.md`](docs/architecture.md) for the full diagrams
(delivery pipeline, runtime/observability, infrastructure). In short:

```text
push → GitHub Actions (lint→test→SAST→build→Trivy→SBOM→Cosign) → GHCR/ECR
     → GitOps repo → Argo CD → Kubernetes (EKS / local kind)
     → Prometheus / Grafana / Loki / OpenTelemetry → SLOs → Alerts → Runbooks
```

## Repository layout

| Path | Area | Status |
|------|------|--------|
| [`app/`](app/) | Demo microservices (FastAPI: user / order / worker) | 🟡 scaffold |
| [`terraform/`](terraform/) | AWS infra as code (VPC, EKS, RDS, Redis, ECR, IAM/OIDC) | 🟡 scaffold |
| [`helm/`](helm/) | App packaging (Chart + dev/prod values) | 🟡 scaffold |
| [`k8s/`](k8s/) | Base manifests + Kustomize overlays | 🟡 scaffold |
| [`gitops/`](gitops/) | Argo CD app-of-apps + applications | 🟡 scaffold |
| [`.github/workflows/`](.github/workflows/) | DevSecOps CI/CD pipeline | 🟡 scaffold |
| [`observability/`](observability/) | Prometheus, Grafana, Loki, OTel, Alertmanager | 🟡 scaffold |
| [`security/`](security/) | Supply-chain policies (Trivy/SBOM/Cosign) | 🟡 scaffold |
| [`chaos/`](chaos/) | Chaos Mesh experiments (pod kill, latency) | 🟡 scaffold |
| [`load/`](load/) | k6 load tests with SLO thresholds | 🟡 scaffold |
| [`docs/`](docs/) | Architecture, ADRs, runbooks, postmortem template | ✅ written |
| [`networking/`](networking/) | CloudFront/WAF/ALB/Ingress, TLS/ACM | 📋 planned |
| [`disaster-recovery/`](disaster-recovery/) | RPO/RTO, backups, region failover | 📋 planned |
| [`finops/`](finops/) | Cost dashboards & optimisation | 📋 planned |
| [`servicemesh/`](servicemesh/) | Istio (mTLS, canary, telemetry) | 📋 planned |
| [`platform/`](platform/) | Backstage internal developer platform | 📋 planned |

## Run it locally (free, no AWS)

The whole platform loop can run on a local Kubernetes cluster at zero cost:

```bash
# 1. Run the app's tests
cd app/user-api && pip install -r requirements-dev.txt && pytest -q

# 2. Bring up a local cluster + Argo CD, which deploys the app via GitOps
./scripts/kind-bootstrap.sh

# 3. Load-test it
k6 run load/k6-load.js
```

Check the Terraform without applying it:

```bash
terraform -chdir=terraform fmt -recursive -check
# (terraform init + validate per environment once providers are available)
```

## Phased roadmap

```text
P1 Foundations (repo, app, CI)      ✅ scaffolded
P2 Terraform (VPC→EKS→RDS→…)         🟡 written, validate-clean, not applied
P3 Kubernetes + Helm                 🟡 scaffold
P4 GitOps (Argo CD)                  🟡 scaffold
P5 Observability (metrics/logs/trace)🟡 scaffold
P6 DevSecOps (Trivy/SBOM/Cosign)     🟡 in CI
P7 SRE (SLOs, error budgets, alerts) 🟡 rules scaffolded
P8 Chaos + Load                      🟡 scaffold
P9 HA / DR / FinOps                  📋 planned
P10 Service Mesh (Istio)             📋 planned
P11 Platform (Backstage)             📋 planned
```

The recommended next step is **P1→P5 locally on `kind`** (the same way the
[Reliability Lab](https://github.com/sayaksatpathi/my-first-devops-project) was
verified with real screenshots), then write the AWS layer with `plan` output as
evidence. Build one phase at a time; keep each one honest and runnable.

## License

[MIT](LICENSE) © 2026 Sayak Satpathi
