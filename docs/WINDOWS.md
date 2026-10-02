# Running OpsForge on Windows (WSL2)

Everything runs in **WSL2 (Ubuntu)** — not PowerShell, because the scripts are
Bash and use `&&`, `.sh`, and `<` redirects.

## Prerequisites
- **WSL2 + Ubuntu** (`wsl --install` in PowerShell, then reboot).
- **Docker** in WSL, with the Compose v2 plugin:
  ```bash
  sudo apt update
  sudo apt install -y docker.io docker-compose-v2
  sudo usermod -aG docker "$USER"   # then close & reopen the terminal
  docker compose version            # must print a version
  ```
  (Docker Desktop with WSL integration also works.)

## 1. Clone and test the app (no containers)
```bash
git clone https://github.com/sayaksatpathi/my-second-devops-project
cd my-second-devops-project/app/user-api
python3 -m venv .venv          # Ubuntu blocks system pip; a venv is required
source .venv/bin/activate
pip install -r requirements-dev.txt
pytest -q
deactivate
cd ../..
```

## 2. Run the full stack
```bash
docker compose up -d --build
docker compose ps              # every service should be Up / healthy
```
Open: Grafana http://localhost:3000 (admin/admin) · Prometheus http://localhost:9090
· Jaeger http://localhost:16686

Drive traffic (second terminal) to light up the dashboards:
```bash
while true; do curl -s "http://localhost:8000/work?fail_rate=0.1&max_ms=120" >/dev/null; done
```

## 3. The Kubernetes demo (kind)
```bash
# install kind + kubectl + helm first (see their docs), then:
./scripts/kind-demo.sh
```

## Troubleshooting (things you may hit)
| Symptom | Fix |
|---------|-----|
| `The token '&&' is not valid` | You're in PowerShell — use WSL/Ubuntu (bash) |
| `externally-managed-environment` (pip) | Use a `venv` (step 1), never system pip |
| `unknown command: docker compose` | `sudo apt install docker-compose-v2` |
| `postgres exited (1)` on `up` | Stale volume from an interrupted run → `docker compose down -v` then `up` again |
| Everything slow / OOM | Give WSL more RAM: create `C:\Users\<you>\.wslconfig` with `[wsl2]` + `memory=8GB`, then `wsl --shutdown` |

## Tear down
```bash
docker compose down -v      # stack + volumes
kind delete cluster --name opsforge
```
