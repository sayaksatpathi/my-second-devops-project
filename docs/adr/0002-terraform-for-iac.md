# ADR 0002: Use Terraform for infrastructure as code

**Status:** Accepted

## Context
Infrastructure must be reproducible, reviewable, and environment-separated.

## Decision
Use Terraform with reusable **modules** (`terraform/modules/*`) composed by
per-environment stacks (`terraform/environments/{dev,staging,production}`),
with **remote state + state locking** (S3 + DynamoDB).

## Consequences
+ Reproducible, reviewable infra; drift detection via `plan`.
− State management and module versioning add process overhead.

## Alternatives considered
CloudFormation (AWS-only, verbose), Pulumi (great, but Terraform is the
industry baseline this project targets).
