SHELL := /bin/bash
ROOT_DIR := $(shell pwd)
ENV_DIRS := environments/dev environments/prod
ENV ?= dev
platform ?= ecs

.PHONY: fmt fmt-check validate lint security docs docs-check test plan apply cost

fmt:
	terraform fmt -recursive

fmt-check:
	terraform fmt -recursive -check

validate:
	terraform -chdir=bootstrap init -backend=false -input=false >/dev/null
	terraform -chdir=bootstrap validate
	@for dir in $(ENV_DIRS); do \
		terraform -chdir=$$dir init -backend=false -input=false >/dev/null; \
		terraform -chdir=$$dir validate; \
	done

lint:
	tflint --init
	tflint --config $(ROOT_DIR)/.tflint.hcl --chdir bootstrap
	@for dir in $(ENV_DIRS); do \
		tflint --config $(ROOT_DIR)/.tflint.hcl --chdir $$dir; \
	done

security:
	tfsec .

docs:
	@for dir in modules/*; do \
		terraform-docs markdown table --output-file README.md --output-mode inject $$dir; \
	done

docs-check:
	@for dir in modules/*; do \
		terraform-docs markdown table --output-file README.md --output-mode inject --output-check $$dir; \
	done

test:
	terraform -chdir=bootstrap init -backend=false -input=false >/dev/null
	terraform -chdir=bootstrap test
	terraform -chdir=tests/terraform init -backend=false -input=false >/dev/null
	terraform -chdir=tests/terraform test

plan:
	terraform -chdir=environments/$(ENV) init -backend-config=backend.hcl
	terraform -chdir=environments/$(ENV) plan -var-file=terraform.tfvars -var "platform=$(platform)"

apply:
	terraform -chdir=environments/$(ENV) init -backend-config=backend.hcl
	terraform -chdir=environments/$(ENV) apply -var-file=terraform.tfvars -var "platform=$(platform)"

cost:
	@test -n "$$INFRACOST_API_KEY" || (echo "INFRACOST_API_KEY is required"; exit 1)
	TF_CLI_ARGS_init="-backend=false -input=false" TF_CLI_ARGS_plan="-input=false" infracost breakdown --config-file infracost.yml
