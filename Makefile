# OpsForge — common tasks. `make help` lists them.
SHELL := /bin/bash
TF_DEV := terraform/environments/dev
TF_DR  := terraform/environments/dr

.PHONY: help test compose-up compose-down kind-demo \
        tf-fmt tf-validate tf-plan-dev tf-apply-dev tf-destroy-dev

help: ## List targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-16s\033[0m %s\n",$$1,$$2}'

test: ## Run the app unit tests
	cd app/user-api && python3 -m venv .venv && . .venv/bin/activate && \
	  pip install -q -r requirements-dev.txt && pytest -q

compose-up: ## Start the full local stack
	docker compose up -d --build

compose-down: ## Stop the stack and wipe volumes
	docker compose down -v

kind-demo: ## Run the full Kubernetes runtime demo (kind)
	./scripts/kind-demo.sh

tf-fmt: ## Format all Terraform
	terraform -chdir=terraform fmt -recursive

tf-validate: ## Validate the dev stack
	terraform -chdir=$(TF_DEV) init -backend=false && terraform -chdir=$(TF_DEV) validate

tf-plan-dev: ## Plan the dev stack (read-only; needs AWS creds)
	cd $(TF_DEV) && terraform init && terraform plan

tf-apply-dev: ## Apply the dev stack — CREATES BILLABLE AWS RESOURCES
	@echo "⚠️  This creates real AWS resources (~\$$230-260/mo). Ctrl-C to abort."
	@read -p "Type 'apply' to continue: " c && [ "$$c" = "apply" ]
	cd $(TF_DEV) && terraform init && terraform apply

tf-destroy-dev: ## Destroy the dev stack (stops billing)
	cd $(TF_DEV) && terraform destroy
