# Infrastructure as Code (Terraform)

**Status:** 🟡 scaffold

Provisions all AWS infrastructure (VPC, EKS, RDS, Redis, ECR, IAM, monitoring) via reusable modules and per-environment stacks with remote state + locking. Written to be `validate`-clean; **not applied from this scaffold** (requires a real AWS account).

> Part of **OpsForge** — see the [root README](../../README.md) for the full architecture and roadmap.
