# ADR 0006: Local-first, zero-cost verification

**Status:** Accepted

## Context
A live AWS platform costs real money and can't always be left running. The
project must still be *verifiable*.

## Decision
Everything that can run locally runs on a **kind** cluster for free (Argo CD,
Prometheus/Grafana/Loki, the app, chaos, load). The AWS/Terraform layer is
written and kept `validate`-clean, with `terraform plan` output captured as
evidence, but applied only when a real environment is funded.

## Consequences
+ The platform is demonstrable at zero cost with real evidence.
− The cloud layer is proven by plan/validate, not a running account, until funded.
