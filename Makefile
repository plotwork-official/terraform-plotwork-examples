# Run from the repository root. PROVIDER_DIR builds the provider from a
# checkout instead of installing it from the registry.
PROVIDER_DIR ?=
SHELL := bash
EXAMPLES := $(shell find examples -name versions.tf -exec dirname {} \; | sort)

.PHONY: help fmt fmt-check validate lint smoke-fake smoke-preview smoke-production pulumi-fake pulumi-preview denials-fake denials-preview denials-production

help: ## List the targets
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{ printf "  %-18s %s\n", $$1, $$2 }'

fmt: ## Format every .tf file
	terraform fmt -recursive .

fmt-check: ## Fail on unformatted .tf files
	terraform fmt -recursive -check -diff .

validate: ## terraform init (no backend) and validate in every example
	@set -e; \
	if [ -n "$(PROVIDER_DIR)" ]; then source tests/lib/provider-mirror.sh; install_provider_mirror "$(PROVIDER_DIR)" "$$(mktemp -d)"; fi; \
	for dir in $(EXAMPLES); do \
		echo "== $$dir"; \
		terraform -chdir=$$dir init -backend=false -input=false >/dev/null && terraform -chdir=$$dir validate -no-color || exit 1; \
	done

lint: ## TFLint every example (fixtures are sample input and are not linted)
	tflint --init --config "$(CURDIR)/.tflint.hcl"
	@set -e; for dir in $(EXAMPLES); do echo "== $$dir"; tflint --chdir=$$dir --config "$(CURDIR)/.tflint.hcl"; done

smoke-fake: ## Run every example against the fake API: no key, no account
	PLOTWORK_PROVIDER_SOURCE_DIR=$(PROVIDER_DIR) tests/smoke/run-smoke.sh fake

smoke-preview: ## Run every example against preview (needs PLOTWORK_API_KEY)
	PLOTWORK_PROVIDER_SOURCE_DIR=$(PROVIDER_DIR) tests/smoke/run-smoke.sh preview

smoke-production: ## Run every example against production (needs PLOTWORK_API_KEY)
	PLOTWORK_PROVIDER_SOURCE_DIR=$(PROVIDER_DIR) tests/smoke/run-smoke.sh production

pulumi-fake: ## Run the Pulumi example against the fake API (needs pulumi and node)
	tests/pulumi/run-pulumi.sh fake

pulumi-preview: ## Run the Pulumi example against preview (needs PLOTWORK_API_KEY)
	tests/pulumi/run-pulumi.sh preview

denials-fake: ## Check the Free plan's refusals against the fake API
	PLOTWORK_PROVIDER_SOURCE_DIR=$(PROVIDER_DIR) tests/denials/run-denials.sh fake

denials-preview: ## Check the Free plan's refusals on preview (a Free key; PLOTWORK_ORG a Free organisation)
	PLOTWORK_PROVIDER_SOURCE_DIR=$(PROVIDER_DIR) tests/denials/run-denials.sh preview

denials-production: ## Check the Free plan's refusals on production
	PLOTWORK_PROVIDER_SOURCE_DIR=$(PROVIDER_DIR) tests/denials/run-denials.sh production
