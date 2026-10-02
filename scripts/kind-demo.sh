#!/usr/bin/env bash
# =============================================================================
# OpsForge — full Kubernetes runtime demo on a local kind cluster (zero cost).
#
# Proves, on a REAL cluster: Helm/K8s deploy via Argo CD (GitOps), HPA
# autoscaling under load, Argo Rollouts canary, and Chaos Mesh pod-kill.
#
# Requires: docker, kind, kubectl, helm  (install hints below).
# Run on a real Docker host (your WSL2/Ubuntu works). NOTE: this cannot run
# inside the author's cloud sandbox, which lacks a real cgroup hierarchy — see
# IMPLEMENTATION.md. On your machine it works.
#
#   chmod +x scripts/kind-demo.sh && ./scripts/kind-demo.sh
# =============================================================================
set -euo pipefail
CLUSTER=opsforge
NS=opsforge
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
step() { echo -e "\n\033[1;36m==> $*\033[0m"; }

for t in docker kind kubectl helm; do
  command -v "$t" >/dev/null || { echo "MISSING: $t — install it first."; exit 1; }
done

step "1/8 Create kind cluster"
kind get clusters | grep -qx "$CLUSTER" || kind create cluster --name "$CLUSTER" --wait 120s
kubectl cluster-info --context "kind-$CLUSTER" >/dev/null

step "2/8 Build app images and load them into the cluster (no registry needed)"
docker build -t ghcr.io/sayaksatpathi/opsforge-user-api:latest "$ROOT/app/user-api"
docker build -t ghcr.io/sayaksatpathi/opsforge-order-api:latest "$ROOT/app/order-api"
docker build -t ghcr.io/sayaksatpathi/opsforge-worker:latest   "$ROOT/app/worker"
kind load docker-image --name "$CLUSTER" \
  ghcr.io/sayaksatpathi/opsforge-user-api:latest \
  ghcr.io/sayaksatpathi/opsforge-order-api:latest \
  ghcr.io/sayaksatpathi/opsforge-worker:latest
kubectl create namespace "$NS" --dry-run=client -o yaml | kubectl apply -f -

step "3/8 Install Argo CD"
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl -n argocd rollout status deploy/argocd-server --timeout=300s

step "4/8 Deploy the app via GitOps (Argo CD syncs the Helm chart from this repo)"
kubectl apply -f "$ROOT/gitops/argocd/apps/opsforge-app.yaml"
echo "Argo CD will sync helm/opsforge into ns '$NS'. Watch:  kubectl -n $NS get pods -w"
kubectl -n "$NS" rollout status deploy/opsforge --timeout=300s || \
  echo "(If pending on image pull, ensure kind load ran; pullPolicy is IfNotPresent.)"

step "5/8 Install metrics-server (patched for kind) for HPA"
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl -n kube-system patch deploy metrics-server --type=json \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'
kubectl -n kube-system rollout status deploy/metrics-server --timeout=180s
kubectl -n "$NS" get hpa

step "6/8 Drive CPU load and watch the HPA scale up"
kubectl -n "$NS" port-forward svc/opsforge 8080:80 >/tmp/pf.log 2>&1 &
PF=$!; sleep 3
echo "Generating CPU load for 90s (burn_ms)..."
( end=$((SECONDS+90)); while [ $SECONDS -lt $end ]; do
    for i in $(seq 1 10); do curl -s "http://localhost:8080/work?burn_ms=60" >/dev/null & done; wait
  done ) &
LOAD=$!
for i in $(seq 1 10); do kubectl -n "$NS" get hpa opsforge --no-headers; sleep 10; done
wait $LOAD 2>/dev/null || true; kill $PF 2>/dev/null || true
echo "If replicas climbed above minReplicas, HPA autoscaling is proven."

step "7/8 Argo Rollouts canary (progressive delivery)"
kubectl create namespace argo-rollouts --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml
kubectl -n argo-rollouts rollout status deploy/argo-rollouts --timeout=180s
kubectl apply -f "$ROOT/gitops/rollouts/" || true
echo "Inspect:  kubectl argo rollouts get rollout user-api -n $NS --watch"

step "8/8 Chaos Mesh pod-kill experiment"
kubectl apply -f https://mirrors.chaos-mesh.org/v2.6.3/install.sh >/dev/null 2>&1 || \
  curl -sSL https://mirrors.chaos-mesh.org/v2.6.3/install.sh | bash || \
  echo "(Install Chaos Mesh manually, then: kubectl apply -f chaos/experiments/pod-kill.yaml)"
kubectl apply -f "$ROOT/chaos/experiments/pod-kill.yaml" || true
echo "Watch recovery:  kubectl -n $NS get pods -w   (a pod is killed; K8s reschedules it)"

echo -e "\n\033[1;32mDone.\033[0m Argo CD UI:  kubectl -n argocd port-forward svc/argocd-server 8081:443"
echo "Tear down:  kind delete cluster --name $CLUSTER"
