# OpsForge — Architecture

OpsForge is a production-style, cloud-native DevSecOps & SRE platform. A
developer pushes code; the platform tests it, secures it, builds and signs a
container, deploys it via GitOps to Kubernetes, and observes it with full
metrics/logs/traces, SLOs, alerting, and incident tooling.

## Delivery pipeline

```mermaid
flowchart LR
    dev[Developer push] --> ci{{GitHub Actions}}
    ci --> lint[Lint + Unit tests]
    lint --> sast[SAST + dependency scan]
    sast --> build[Docker build]
    build --> scan[Trivy scan]
    scan --> sbom[SBOM - Syft]
    sbom --> sign[Sign - Cosign]
    sign --> ecr[(ECR / GHCR)]
    ecr --> gitops[Update GitOps repo]
    gitops --> argo[Argo CD]
    argo --> k8s[(Kubernetes)]
```

## Runtime & observability

```mermaid
flowchart LR
    net[CloudFront -> WAF -> ALB -> Ingress] --> svc[Services: user / order / worker]
    svc --> pg[(PostgreSQL)]
    svc --> redis[(Redis)]
    svc --> kafka[(Kafka)]
    svc -- /metrics --> prom[Prometheus]
    svc -- logs --> loki[Loki]
    svc -- traces --> otel[OpenTelemetry]
    prom --> graf[Grafana]
    loki --> graf
    otel --> graf
    prom --> am[Alertmanager]
    am --> oncall[On-call + runbooks]
```

## Infrastructure (Terraform)

```mermaid
flowchart TD
    tf[Terraform] --> vpc[VPC + subnets + NAT]
    tf --> eks[EKS]
    tf --> rds[RDS PostgreSQL]
    tf --> redis[ElastiCache Redis]
    tf --> ecr[ECR]
    tf --> iam[IAM / OIDC]
    tf --> mon[Monitoring]
```

See [`../README.md`](../README.md) for the phased roadmap and the status of
each area, and [`adr/`](adr/) for the decisions behind these choices.
