# Ansible — node/config management

**Where it fits:** Terraform provisions cloud *infrastructure* (VPC, EKS, RDS);
Kubernetes/Helm/Argo CD deploy *workloads*; **Ansible** handles *node and OS
configuration* and bootstrap tasks that live below the cluster (base packages,
hardening, agents) — the classic IaC + config-management split.

Run (local, safe):
```bash
cd ansible
ansible-playbook playbooks/site.yml --syntax-check
ansible-playbook playbooks/site.yml           # runs against localhost
```
