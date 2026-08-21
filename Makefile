# Makefile for the Terraform CORS Project.
#
# Targets operate on every Terraform module under modules/ and examples/.

SHELL := /bin/bash
TF_DIRS := $(shell find modules examples -maxdepth 2 -name '*.tf' -printf '%h\n' | sort -u)
TFDOCS_VERSION ?= v0.19.0
TFLINT_VERSION ?= v0.64.0

.PHONY: help fmt fmt-check validate lint security docs clean

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

fmt: ## Format all Terraform files
	@for d in $(TF_DIRS); do echo "==> fmt $$d"; terraform fmt -recursive $$d; done

fmt-check: ## Check formatting without changing files
	@for d in $(TF_DIRS); do echo "==> fmt check $$d"; terraform fmt -check -recursive -diff $$d; done

validate: ## terraform init -backend=false + validate in every directory
	@for d in $(TF_DIRS); do \
		echo "==> validate $$d"; \
		terraform -chdir=$$d init -backend=false -input=false > /dev/null; \
		terraform -chdir=$$d validate -no-color; \
	done

lint: ## Run tflint in every directory
	@tflint --init
	@for d in $(TF_DIRS); do echo "==> lint $$d"; tflint --chdir=$$d --config $(CURDIR)/.tflint.hcl; done

security: ## Run trivy (tfsec) static security scan
	@trivy config --severity HIGH,CRITICAL --scanners misconfig $(CURDIR)

docs: ## Regenerate README.md for every module with terraform-docs
	@for d in $(TF_DIRS); do \
		case "$$d" in examples/*) continue ;; esac; \
		echo "==> docs $$d"; \
		terraform-docs markdown table --config $(CURDIR)/.terraform-docs.yml $$d; \
	done

clean: ## Remove generated Terraform artifacts
	@find $(CURDIR) -type d -name .terraform -prune -exec rm -rf {} +
	@rm -f tfplan drift-plan drift.log
