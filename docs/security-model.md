# Security Model

## Supply chain (CI)
Secret scan (Gitleaks) → SAST (Bandit) + dependency audit (pip-audit) →
image build → **Trivy** vulnerability scan → **SBOM** (Syft) → **Cosign**
keyless signature → push to GHCR. Clusters verify signatures before admitting images.

## Identity & secrets
- **GitHub → AWS via OIDC** (`terraform/modules/iam`) — no long-lived AWS keys.
- Secrets come from AWS Secrets Manager / Kubernetes Secrets; **never hardcoded**
  (app config is 100% env-driven; `gitleaks` confirms no leaks).

## Runtime hardening
- Containers run **non-root** (uid 10001), read-only root filesystem, dropped
  capabilities, `seccompProfile: RuntimeDefault` (Helm `securityContext`).
- **NetworkPolicy** default-deny ingress; **RBAC** least-privilege Role.
- **Istio mTLS STRICT** between services.

## IaC security
`checkov` + `trivy config` run against Terraform/K8s/Dockerfiles. Findings are
triaged in `evidence/checkov-terraform.txt` (hardened: S3 SSE+public-access-block,
RDS logging/deletion-protection; remaining items are documented trade-offs).

## What each check protects against
| Check | Threat |
|-------|--------|
| Gitleaks | Committed credentials |
| Trivy image | Known CVEs in base image / deps |
| SBOM + Cosign | Tampered/untrusted images, supply-chain provenance |
| checkov/tfsec | Misconfigured cloud resources (open SGs, unencrypted storage) |
| NetworkPolicy | Lateral movement between pods |
