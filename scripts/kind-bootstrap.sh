#!/usr/bin/env bash
# Spin up a FREE local platform: kind + Argo CD + the app. Zero AWS cost.
set -euo pipefail
kind create cluster --name opsforge || true
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
echo "Waiting for Argo CD..."; kubectl -n argocd rollout status deploy/argocd-server --timeout=300s
kubectl apply -f gitops/argocd/root-app.yaml
echo "Done. Port-forward Argo CD:  kubectl -n argocd port-forward svc/argocd-server 8080:443"
