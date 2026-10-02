# FinOps — Cost Model (ESTIMATES)

> ⚠️ These are **architecture-based estimates** (us-east-1, on-demand), **not**
> real billing. Actual cost depends on usage.

| Component | Rough monthly estimate (USD) |
|-----------|------------------------------|
| EKS control plane | ~$73 |
| 2× t3.medium nodes | ~$60 |
| RDS db.t3.micro Multi-AZ | ~$30 |
| ElastiCache t3.micro | ~$12 |
| NAT Gateway (1) | ~$32 + data |
| ALB | ~$16 + LCU |
| S3 / ECR / CloudWatch | ~$5–15 |
| **Rough total (dev)** | **~$230–260 / mo** |

## Optimisation levers (with trade-offs)
- **Single NAT** in dev (done) vs. one-per-AZ in prod (HA ↔ cost).
- **Spot** node groups for stateless workloads (cost ↔ interruption).
- **Right-size** nodes/HPA from real metrics (over-provisioning is the #1 waste).
- **Storage lifecycle** (S3 IA/Glacier; ECR keep-last-20 — already configured).
- **VPC endpoints** to cut NAT data-processing charges.
- Consistent **tagging** (`Project`/`Environment`) for cost allocation.
