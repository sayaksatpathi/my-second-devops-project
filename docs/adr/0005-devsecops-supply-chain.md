# ADR 0005: Shift-left supply-chain security

**Status:** Accepted

## Context
Security must be part of the pipeline, not a document.

## Decision
CI runs SAST + dependency scan, scans images with **Trivy**, generates an
**SBOM** with **Syft**, and signs images with **Cosign**. Clusters verify
signatures before admitting images. AWS access uses **OIDC** (no long-lived keys).

## Consequences
+ Vulnerabilities and unsigned images are caught before deploy.
− Slightly slower pipeline; signing keys/OIDC must be managed.
