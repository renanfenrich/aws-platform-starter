SHELL := /bin/bash
ROOT_DIR := $(shell pwd)
ENV_DIRS := environments/dev environments/prod environments/dr
ENV ?= dev
platform ?= ecs
MERMAID_CLI_VERSION ?= 10.9.1
MERMAID_CLI := npx -y @mermaid-js/mermaid-cli@$(MERMAID_CLI_VERSION)
DIAGRAM_SRC := docs/architecture.mmd
DIAGRAM_OUT := docs/architecture.svg

.PHONY: fmt fmt-check validate lint security docs docs-check diagram test plan apply cost

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

diagram:
	$(MERMAID_CLI) -i $(DIAGRAM_SRC) -o $(DIAGRAM_OUT) -t neutral

test:
	terraform -chdir=bootstrap init -backend=false -input=false >/dev/null
	terraform -chdir=bootstrap test
	terraform -chdir=tests/terraform init -backend=false -input=false >/dev/null
	terraform -chdir=tests/terraform test
	@for dir in $(ENV_DIRS); do \
		terraform -chdir=$$dir init -backend=false -input=false >/dev/null; \
		terraform -chdir=$$dir test; \
	done
	@for dir in modules/network modules/alb modules/apigw-lambda modules/backup-vault modules/ecs modules/ecs-ec2-capacity modules/eks modules/k8s-ec2-infra modules/rds modules/observability; do \
		terraform -chdir=$$dir init -backend=false -input=false >/dev/null; \
		terraform -chdir=$$dir test; \
	done

plan:
	terraform -chdir=environments/$(ENV) init -backend-config=backend.hcl
	terraform -chdir=environments/$(ENV) plan -var-file=terraform.tfvars -var "platform=$(platform)"

apply:
	terraform -chdir=environments/$(ENV) init -backend-config=backend.hcl
	terraform -chdir=environments/$(ENV) apply -var-file=terraform.tfvars -var "platform=$(platform)"

cost:
	@test -n "$$INFRACOST_API_KEY" || (echo "INFRACOST_API_KEY is required"; exit 1)
	TF_CLI_ARGS_init="-backend=false -input=false" TF_CLI_ARGS_plan="-input=false" infracost breakdown --config-file infracost.yml
