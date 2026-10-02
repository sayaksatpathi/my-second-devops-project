# Evidence

Real output captured from this environment. Nothing here is fabricated.

| File | What it proves |
|------|----------------|
| `integration-test.txt` | user-api + Postgres + Redis: persistence, cache, JSON logs |
| `kafka-test.txt` | order-api → Kafka → worker; poison message → DLQ |
| `backup-restore-and-chaos.txt` | pg_dump/restore round-trip; Redis-failure graceful degradation |
| `k6-load.txt` | Load test: 10,702 reqs @152 rps, p95=99ms, 0% failures |
| `ansible-run.txt` | Playbook syntax-check + localhost run; idempotent re-run (changed=0) |
| `checkov-terraform.txt` | IaC security scan summary (55 pass / 23 triaged) |
| `trivy-config.txt`, `trivy-secrets.txt` | Container/IaC misconfig + secret scan |
| `sbom-user-api.spdx.json`, `sbom-user-api.txt` | SBOM (16 packages) |
| `gitleaks.txt` | Secret scan: no leaks found |
| `screenshots/grafana-api-overview.png` | Golden-signals dashboard, live data |
| `screenshots/grafana-slo.png` | SLO & error-budget dashboard |
| `screenshots/prometheus-alerts.png` | ErrorBudgetFastBurn firing |
| `screenshots/alertmanager.png` | Alert received + grouped in Alertmanager |
| `screenshots/jaeger-traces.png` | 20 distributed traces (OTel → Jaeger) |
