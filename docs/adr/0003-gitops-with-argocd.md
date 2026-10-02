# ADR 0003: Continuous delivery via GitOps (Argo CD)

**Status:** Accepted

## Context
We want the cluster's state to always match a Git source of truth, with
auditable changes and automatic drift correction.

## Decision
CI builds and pushes images, then updates the **GitOps repo**; **Argo CD**
reconciles the cluster to match. Manual cluster edits are reverted by
reconciliation.

## Consequences
+ Declarative, auditable deploys; easy rollback (git revert).
− Requires discipline: no `kubectl apply` by hand in managed namespaces.
