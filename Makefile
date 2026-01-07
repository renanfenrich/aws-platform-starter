SHELL := /bin/bash
ROOT_DIR := $(shell pwd)
ENV_DIRS := environments/dev environments/prod

.PHONY: fmt fmt-check validate lint security docs docs-check test

fmt:
	terraform fmt -recursive

fmt-check:
	terraform fmt -recursive -check

validate:
	@for dir in $(ENV_DIRS); do \
		terraform -chdir=$$dir init -backend=false -input=false >/dev/null; \
		terraform -chdir=$$dir validate; \
	done

lint:
	tflint --init
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
	terraform -chdir=tests/terraform init -backend=false -input=false >/dev/null
	terraform -chdir=tests/terraform test
