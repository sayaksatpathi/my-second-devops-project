# OpsForge convenience targets (local, zero-cost workflow)
.PHONY: help app-test tf-validate tf-fmt helm-lint kind-up kind-down

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-14s\033[0m %s\n",$$1,$$2}'

app-test: ## Run the demo app's unit tests
	cd app/user-api && python -m pytest -q

tf-fmt: ## Format all Terraform
	terraform -chdir=terraform fmt -recursive

tf-validate: ## Validate the dev environment (needs `terraform init`)
	terraform -chdir=terraform/environments/dev validate

helm-lint: ## Lint the Helm chart
	helm lint helm/opsforge

kind-up: ## Create a local kind cluster for free, local testing
	kind create cluster --name opsforge

kind-down: ## Delete the local kind cluster
	kind delete cluster --name opsforge
