# Colors
export RED := $(shell printf '\033[0;31m')
export GREEN := $(shell printf '\033[0;32m')
export YELLOW := $(shell printf '\033[1;33m')
export BLUE := $(shell printf '\033[0;34m')
export CYAN := $(shell printf '\033[0;36m')
export MAGENTA := $(shell printf '\033[0;35m')
export BOLD := $(shell printf '\033[1m')
export NC := $(shell printf '\033[0m')

.PHONY: help
help: ## Show this help message
	@printf '\n'
	@printf '$(CYAN)╔══════════════════════════════════════════════════════════════╗$(NC)\n'
	@printf '$(CYAN)║$(NC)  $(BOLD)$(MAGENTA)Tutum Pro CI/CD Ansible Collection$(NC)                          $(CYAN)║$(NC)\n'
	@printf '$(CYAN)╚══════════════════════════════════════════════════════════════╝$(NC)\n'
	@printf '\n'
	@printf '$(CYAN)Usage:$(NC) make $(GREEN)[target]$(NC) $(YELLOW)[INVENTORY=path] [EXTRA_VARS="-e key=val"]$(NC)\n'
	@printf '\n'
	@printf '$(YELLOW)Variables:$(NC)\n'
	@printf '  $(GREEN)INVENTORY$(NC)    Path to inventory file $(BLUE)(default: inventory/hosts.yml)$(NC)\n'
	@printf '  $(GREEN)EXTRA_VARS$(NC)   Extra ansible variables $(BLUE)(e.g., -e remove_data=true)$(NC)\n'
	@printf '\n'
	@printf '$(YELLOW)Examples:$(NC)\n'
	@printf '  make install-engine\n'
	@printf '  make collection-build\n'
	@printf '  make uninstall-all EXTRA_VARS="-e remove_data=true -e remove_volumes=true"\n'
	@printf '\n'
	@printf '$(YELLOW)Available targets:$(NC)\n'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(GREEN)%-25s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@printf '\n'

# Variables
VERSION?=$(shell cat version 2>/dev/null || echo "0.0.0")
INVENTORY?=inventory/hosts.yml
EXTRA_VARS?=
NAMESPACE?=tutum_pro
COLLECTION_NAME?=cicd

## Collection Management

.PHONY: collection-build
collection-build: collection-sync-version ## Build Ansible collection tarball
	@printf "\n$(CYAN)╔══════════════════════════════════════════════════════════════╗$(NC)\n"
	@printf "$(CYAN)║$(NC)  $(BOLD)Building Ansible Collection$(NC)                                 $(CYAN)║$(NC)\n"
	@printf "$(CYAN)╚══════════════════════════════════════════════════════════════╝$(NC)\n\n"
	ansible-galaxy collection build --force
	@printf "\n$(GREEN)✓$(NC) Collection built: $(NAMESPACE)-$(COLLECTION_NAME)-$(VERSION).tar.gz\n\n"

.PHONY: collection-install
collection-install: collection-build ## Install collection locally
	@printf "\n$(CYAN)╔══════════════════════════════════════════════════════════════╗$(NC)\n"
	@printf "$(CYAN)║$(NC)  $(BOLD)Installing Collection Locally$(NC)                               $(CYAN)║$(NC)\n"
	@printf "$(CYAN)╚══════════════════════════════════════════════════════════════╝$(NC)\n\n"
	ansible-galaxy collection install $(NAMESPACE)-$(COLLECTION_NAME)-$(VERSION).tar.gz --force
	@printf "\n$(GREEN)✓$(NC) Collection installed: $(NAMESPACE).$(COLLECTION_NAME)\n\n"

.PHONY: collection-publish
collection-publish: collection-build ## Publish collection to Ansible Galaxy
	@printf "\n$(CYAN)╔══════════════════════════════════════════════════════════════╗$(NC)\n"
	@printf "$(CYAN)║$(NC)  $(BOLD)Publishing to Ansible Galaxy$(NC)                                $(CYAN)║$(NC)\n"
	@printf "$(CYAN)╚══════════════════════════════════════════════════════════════╝$(NC)\n\n"
	@if [ -z "$$GALAXY_API_KEY" ]; then \
		printf "$(RED)Error:$(NC) GALAXY_API_KEY environment variable is required.\n"; \
		printf "$(CYAN)Get your API key from:$(NC) https://galaxy.ansible.com/me/preferences\n\n"; \
		exit 1; \
	fi
	ansible-galaxy collection publish $(NAMESPACE)-$(COLLECTION_NAME)-$(VERSION).tar.gz --api-key $$GALAXY_API_KEY
	@printf "\n$(GREEN)✓$(NC) Collection published to Galaxy!\n"
	@printf "$(CYAN)View at:$(NC) https://galaxy.ansible.com/$(NAMESPACE)/$(COLLECTION_NAME)\n\n"

.PHONY: collection-sync-version
collection-sync-version: ## Sync version from version file to galaxy.yml
	@sed -i 's/^version: .*/version: "$(VERSION)"/' galaxy.yml
	@printf "$(GREEN)✓$(NC) galaxy.yml version synced to $(GREEN)$(VERSION)$(NC)\n"

.PHONY: collection-clean
collection-clean: ## Remove built collection tarballs
	@rm -f $(NAMESPACE)-$(COLLECTION_NAME)-*.tar.gz
	@printf "$(GREEN)✓$(NC) Cleaned collection tarballs\n"

## Version Management

.PHONY: version
version: ## Show current version
	@printf "$(CYAN)Current version:$(NC) $(GREEN)$(VERSION)$(NC)\n"

.PHONY: bump
bump: ## Bump version (TYPE=f|c|b). f=fix (patch), c=compatible (minor), b=breaking (major)
	@if [ -z "$(TYPE)" ]; then \
		printf "\n$(CYAN)╔══════════════════════════════════════════════════════════════╗$(NC)\n"; \
		printf "$(CYAN)║$(NC)  $(BOLD)Version Bump$(NC)                                                $(CYAN)║$(NC)\n"; \
		printf "$(CYAN)╚══════════════════════════════════════════════════════════════╝$(NC)\n\n"; \
		printf "$(RED)Error:$(NC) TYPE is required.\n\n"; \
		printf "$(CYAN)Usage:$(NC) make bump TYPE=<type>\n\n"; \
		printf "$(YELLOW)Available types:$(NC)\n"; \
		printf "  $(GREEN)TYPE=f$(NC)  $(BLUE)→$(NC)  Fix/patch version bump     $(YELLOW)(1.2.3 → 1.2.4)$(NC)\n"; \
		printf "  $(GREEN)TYPE=c$(NC)  $(BLUE)→$(NC)  Compatible/minor version   $(YELLOW)(1.2.3 → 1.3.0)$(NC)\n"; \
		printf "  $(GREEN)TYPE=b$(NC)  $(BLUE)→$(NC)  Breaking/major version     $(YELLOW)(1.2.3 → 2.0.0)$(NC)\n\n"; \
		exit 1; \
	fi
	@CURRENT=$$(cat version); \
	MAJOR=$$(echo $$CURRENT | cut -d. -f1); \
	MINOR=$$(echo $$CURRENT | cut -d. -f2); \
	PATCH=$$(echo $$CURRENT | cut -d. -f3); \
	case "$(TYPE)" in \
		f) PATCH=$$((PATCH + 1));; \
		c) MINOR=$$((MINOR + 1)); PATCH=0;; \
		b) MAJOR=$$((MAJOR + 1)); MINOR=0; PATCH=0;; \
		*) printf "$(RED)Error:$(NC) Invalid TYPE '$(TYPE)'. Use $(GREEN)f$(NC), $(GREEN)c$(NC), or $(GREEN)b$(NC).\n"; exit 1;; \
	esac; \
	NEW_VERSION="$$MAJOR.$$MINOR.$$PATCH"; \
	echo "$$NEW_VERSION" > version; \
	sed -i 's/^version: .*/version: "'"$$NEW_VERSION"'"/' galaxy.yml; \
	printf "\n$(CYAN)╔══════════════════════════════════════════════════════════════╗$(NC)\n"; \
	printf "$(CYAN)║$(NC)  $(BOLD)$(GREEN)✓ Version Bumped Successfully$(NC)                              $(CYAN)║$(NC)\n"; \
	printf "$(CYAN)╚══════════════════════════════════════════════════════════════╝$(NC)\n\n"; \
	printf "  $(YELLOW)$$CURRENT$(NC)  $(BLUE)→$(NC)  $(GREEN)$$NEW_VERSION$(NC)\n"; \
	printf "\n$(CYAN)Updated files:$(NC)\n"; \
	printf "  $(GREEN)•$(NC) version\n"; \
	printf "  $(GREEN)•$(NC) galaxy.yml\n\n"

.PHONY: tag
tag: ## Create git tag from version file (requires clean committed state)
	@printf "\n$(CYAN)╔══════════════════════════════════════════════════════════════╗$(NC)\n"
	@printf "$(CYAN)║$(NC)  $(BOLD)Git Tag Creation$(NC)                                            $(CYAN)║$(NC)\n"
	@printf "$(CYAN)╚══════════════════════════════════════════════════════════════╝$(NC)\n\n"
	@printf "$(CYAN)Checking git status...$(NC)\n"
	@if [ -n "$$(git status --porcelain)" ]; then \
		printf "$(RED)✗ Error:$(NC) Working directory is not clean.\n"; \
		printf "  $(YELLOW)Commit or stash changes first.$(NC)\n\n"; \
		exit 1; \
	fi
	@VERSION=$$(cat version); \
	if git rev-parse "v$$VERSION" >/dev/null 2>&1; then \
		printf "$(RED)✗ Error:$(NC) Tag $(YELLOW)v$$VERSION$(NC) already exists.\n\n"; \
		exit 1; \
	fi; \
	printf "$(CYAN)Creating tag $(YELLOW)v$$VERSION$(CYAN)...$(NC)\n"; \
	git tag -a "v$$VERSION" -m "Release v$$VERSION"; \
	printf "$(GREEN)✓$(NC) Tag $(GREEN)v$$VERSION$(NC) created successfully.\n\n"; \
	printf "$(CYAN)Next step:$(NC) git push origin v$$VERSION\n\n"

## Installation Playbooks

.PHONY: install-engine
install-engine: ## Install Tutum Engine with PostgreSQL
	@printf "\n$(CYAN)╔══════════════════════════════════════════════════════════════╗$(NC)\n"
	@printf "$(CYAN)║$(NC)  $(BOLD)Installing Tutum Engine$(NC)                                     $(CYAN)║$(NC)\n"
	@printf "$(CYAN)╚══════════════════════════════════════════════════════════════╝$(NC)\n\n"
	ansible-playbook -i $(INVENTORY) playbooks/install-tutum-engine.yml $(EXTRA_VARS)

.PHONY: install-plugin
install-plugin: ## Install Tutum Docker Volume Plugin
	@printf "\n$(CYAN)╔══════════════════════════════════════════════════════════════╗$(NC)\n"
	@printf "$(CYAN)║$(NC)  $(BOLD)Installing Tutum Docker Plugin$(NC)                              $(CYAN)║$(NC)\n"
	@printf "$(CYAN)╚══════════════════════════════════════════════════════════════╝$(NC)\n\n"
	ansible-playbook -i $(INVENTORY) playbooks/install-plugin.yml $(EXTRA_VARS)

.PHONY: install-cli
install-cli: ## Install Tutum Admin CLI container
	@printf "\n$(CYAN)╔══════════════════════════════════════════════════════════════╗$(NC)\n"
	@printf "$(CYAN)║$(NC)  $(BOLD)Installing Tutum Admin CLI$(NC)                                  $(CYAN)║$(NC)\n"
	@printf "$(CYAN)╚══════════════════════════════════════════════════════════════╝$(NC)\n\n"
	ansible-playbook -i $(INVENTORY) playbooks/install-admin-cli.yml $(EXTRA_VARS)

.PHONY: install-all
install-all: install-engine install-plugin install-cli ## Install all components

## Uninstallation Playbooks

.PHONY: uninstall-engine
uninstall-engine: ## Uninstall Tutum Engine and PostgreSQL
	@printf "\n$(CYAN)╔══════════════════════════════════════════════════════════════╗$(NC)\n"
	@printf "$(CYAN)║$(NC)  $(BOLD)$(RED)Uninstalling Tutum Engine$(NC)                                   $(CYAN)║$(NC)\n"
	@printf "$(CYAN)╚══════════════════════════════════════════════════════════════╝$(NC)\n\n"
	ansible-playbook -i $(INVENTORY) playbooks/uninstall-tutum-engine.yml $(EXTRA_VARS)

.PHONY: uninstall-engine-data
uninstall-engine-data: ## Uninstall Tutum Engine with data removal
	@printf "\n$(CYAN)╔══════════════════════════════════════════════════════════════╗$(NC)\n"
	@printf "$(CYAN)║$(NC)  $(BOLD)$(RED)Uninstalling Tutum Engine (with data)$(NC)                       $(CYAN)║$(NC)\n"
	@printf "$(CYAN)╚══════════════════════════════════════════════════════════════╝$(NC)\n\n"
	ansible-playbook -i $(INVENTORY) playbooks/uninstall-tutum-engine.yml -e remove_data=true $(EXTRA_VARS)

.PHONY: uninstall-plugin
uninstall-plugin: ## Uninstall Tutum Docker Volume Plugin
	@printf "\n$(CYAN)╔══════════════════════════════════════════════════════════════╗$(NC)\n"
	@printf "$(CYAN)║$(NC)  $(BOLD)$(RED)Uninstalling Tutum Docker Plugin$(NC)                            $(CYAN)║$(NC)\n"
	@printf "$(CYAN)╚══════════════════════════════════════════════════════════════╝$(NC)\n\n"
	ansible-playbook -i $(INVENTORY) playbooks/uninstall-plugin.yml $(EXTRA_VARS)

.PHONY: uninstall-cli
uninstall-cli: ## Uninstall Tutum Admin CLI container
	@printf "\n$(CYAN)╔══════════════════════════════════════════════════════════════╗$(NC)\n"
	@printf "$(CYAN)║$(NC)  $(BOLD)$(RED)Uninstalling Tutum Admin CLI$(NC)                                $(CYAN)║$(NC)\n"
	@printf "$(CYAN)╚══════════════════════════════════════════════════════════════╝$(NC)\n\n"
	ansible-playbook -i $(INVENTORY) playbooks/uninstall-admin-cli.yml $(EXTRA_VARS)

.PHONY: clean-volumes
clean-volumes: ## Remove all Docker volumes using Tutum plugin
	@printf "\n$(CYAN)╔══════════════════════════════════════════════════════════════╗$(NC)\n"
	@printf "$(CYAN)║$(NC)  $(BOLD)$(RED)Cleaning Tutum Docker Volumes$(NC)                               $(CYAN)║$(NC)\n"
	@printf "$(CYAN)╚══════════════════════════════════════════════════════════════╝$(NC)\n\n"
	@PLUGIN_NAME=$$(grep '^plugin_image:' inventory/group_vars/all.yml | cut -d'"' -f2); \
	PLUGIN_VER=$$(grep '^plugin_version:' inventory/group_vars/all.yml | cut -d'"' -f2); \
	VOLUMES=$$(docker volume ls --filter driver=$$PLUGIN_NAME:$$PLUGIN_VER --format '{{.Name}}' 2>/dev/null); \
	if [ -n "$$VOLUMES" ]; then \
		printf "$(YELLOW)Found volumes using Tutum plugin:$(NC)\n"; \
		echo "$$VOLUMES" | while read vol; do \
			printf "  $(RED)•$(NC) $$vol\n"; \
		done; \
		printf "\n$(CYAN)Removing volumes...$(NC)\n"; \
		echo "$$VOLUMES" | while read vol; do \
			docker volume rm -f "$$vol" 2>/dev/null && printf "  $(GREEN)✓$(NC) Removed $$vol\n" || printf "  $(RED)✗$(NC) Failed to remove $$vol\n"; \
		done; \
		printf "\n$(GREEN)✓$(NC) Volume cleanup completed.\n\n"; \
	else \
		printf "$(GREEN)✓$(NC) No Tutum volumes found.\n\n"; \
	fi

.PHONY: uninstall-all
uninstall-all: clean-volumes uninstall-cli uninstall-plugin uninstall-engine ## Uninstall all components (with volume cleanup)

## Testing

.PHONY: test
test: ## Run integration tests
	@printf "\n$(CYAN)╔══════════════════════════════════════════════════════════════╗$(NC)\n"
	@printf "$(CYAN)║$(NC)  $(BOLD)Running Integration Tests$(NC)                                   $(CYAN)║$(NC)\n"
	@printf "$(CYAN)╚══════════════════════════════════════════════════════════════╝$(NC)\n\n"
	ansible-playbook -i $(INVENTORY) playbooks/integration-test.yml $(EXTRA_VARS)

.PHONY: test-no-cleanup
test-no-cleanup: ## Run integration tests without cleanup
	@printf "\n$(CYAN)╔══════════════════════════════════════════════════════════════╗$(NC)\n"
	@printf "$(CYAN)║$(NC)  $(BOLD)Running Integration Tests (no cleanup)$(NC)                      $(CYAN)║$(NC)\n"
	@printf "$(CYAN)╚══════════════════════════════════════════════════════════════╝$(NC)\n\n"
	ansible-playbook -i $(INVENTORY) playbooks/integration-test.yml -e cleanup_after_test=false $(EXTRA_VARS)

.PHONY: test-cleanup
test-cleanup: ## Cleanup integration test resources
	@printf "\n$(CYAN)╔══════════════════════════════════════════════════════════════╗$(NC)\n"
	@printf "$(CYAN)║$(NC)  $(BOLD)Cleaning Up Integration Test Resources$(NC)                      $(CYAN)║$(NC)\n"
	@printf "$(CYAN)╚══════════════════════════════════════════════════════════════╝$(NC)\n\n"
	ansible-playbook -i $(INVENTORY) playbooks/uninstall-integration-test.yml $(EXTRA_VARS)

.PHONY: report
report: ## Show version report of all installed components
	@printf "\n$(CYAN)╔══════════════════════════════════════════════════════════════╗$(NC)\n"
	@printf "$(CYAN)║$(NC)  $(BOLD)Generating Version Report$(NC)                                   $(CYAN)║$(NC)\n"
	@printf "$(CYAN)╚══════════════════════════════════════════════════════════════╝$(NC)\n\n"
	ansible-playbook -i $(INVENTORY) playbooks/version-report.yml $(EXTRA_VARS)

## Validation

.PHONY: lint
lint: ## Lint all playbooks with ansible-lint
	@printf "\n$(CYAN)╔══════════════════════════════════════════════════════════════╗$(NC)\n"
	@printf "$(CYAN)║$(NC)  $(BOLD)Linting Ansible Playbooks$(NC)                                   $(CYAN)║$(NC)\n"
	@printf "$(CYAN)╚══════════════════════════════════════════════════════════════╝$(NC)\n\n"
	ansible-lint playbooks/*.yml

.PHONY: syntax-check
syntax-check: ## Check playbook syntax
	@printf "\n$(CYAN)╔══════════════════════════════════════════════════════════════╗$(NC)\n"
	@printf "$(CYAN)║$(NC)  $(BOLD)Checking Playbook Syntax$(NC)                                    $(CYAN)║$(NC)\n"
	@printf "$(CYAN)╚══════════════════════════════════════════════════════════════╝$(NC)\n\n"
	@for playbook in playbooks/*.yml; do \
		printf "$(CYAN)Checking:$(NC) $$playbook\n"; \
		ansible-playbook --syntax-check $$playbook || exit 1; \
	done
	@printf "\n$(GREEN)✓$(NC) All playbooks passed syntax check.\n\n"

## Utilities

.PHONY: list-playbooks
list-playbooks: ## List all available playbooks
	@printf "\n$(CYAN)╔══════════════════════════════════════════════════════════════╗$(NC)\n"
	@printf "$(CYAN)║$(NC)  $(BOLD)Available Playbooks$(NC)                                         $(CYAN)║$(NC)\n"
	@printf "$(CYAN)╚══════════════════════════════════════════════════════════════╝$(NC)\n\n"
	@for playbook in playbooks/*.yml; do \
		printf "  $(GREEN)•$(NC) $$(basename $$playbook)\n"; \
	done
	@printf '\n'

.PHONY: status
status: ## Show version and inventory info
	@printf "\n$(CYAN)╔══════════════════════════════════════════════════════════════╗$(NC)\n"
	@printf "$(CYAN)║$(NC)  $(BOLD)Tutum CI/CD Status$(NC)                                          $(CYAN)║$(NC)\n"
	@printf "$(CYAN)╚══════════════════════════════════════════════════════════════╝$(NC)\n\n"
	@printf "  $(YELLOW)Version:$(NC)    $(GREEN)$(VERSION)$(NC)\n"
	@printf "  $(YELLOW)Inventory:$(NC)  $(GREEN)$(INVENTORY)$(NC)\n\n"

.PHONY: show-versions
show-versions: ## Show all component versions from group_vars/all.yml
	@printf "\n$(CYAN)╔══════════════════════════════════════════════════════════════╗$(NC)\n"
	@printf "$(CYAN)║$(NC)  $(BOLD)Component Versions$(NC)                                          $(CYAN)║$(NC)\n"
	@printf "$(CYAN)╚══════════════════════════════════════════════════════════════╝$(NC)\n\n"
	@printf "  $(YELLOW)tutum-cicd:$(NC)        $(GREEN)$(VERSION)$(NC)\n"
	@ENGINE_VER=$$(grep '^tutum_engine_version:' inventory/group_vars/all.yml | cut -d'"' -f2); \
	CLI_VER=$$(grep '^cli_version:' inventory/group_vars/all.yml | cut -d'"' -f2); \
	PLUGIN_VER=$$(grep '^plugin_version:' inventory/group_vars/all.yml | cut -d'"' -f2); \
	PG_VER=$$(grep '^postgres_version:' inventory/group_vars/all.yml | cut -d'"' -f2); \
	printf "  $(YELLOW)tutum-engine:$(NC)      $(GREEN)$$ENGINE_VER$(NC)\n"; \
	printf "  $(YELLOW)tutum-admin-cli:$(NC)   $(GREEN)$$CLI_VER$(NC)\n"; \
	printf "  $(YELLOW)tutum-plugin:$(NC)      $(GREEN)$$PLUGIN_VER$(NC)\n"; \
	printf "  $(YELLOW)postgres:$(NC)          $(GREEN)$$PG_VER$(NC)\n"
	@printf "\n  $(BLUE)Edit: inventory/group_vars/all.yml$(NC)\n\n"

.PHONY: set-version
set-version: ## Set component version (COMPONENT=engine|cli|plugin|postgres VERSION=x.y.z)
	@if [ -z "$(COMPONENT)" ] || [ -z "$(VER)" ]; then \
		printf "\n$(CYAN)╔══════════════════════════════════════════════════════════════╗$(NC)\n"; \
		printf "$(CYAN)║$(NC)  $(BOLD)Set Component Version$(NC)                                       $(CYAN)║$(NC)\n"; \
		printf "$(CYAN)╚══════════════════════════════════════════════════════════════╝$(NC)\n\n"; \
		printf "$(RED)Error:$(NC) COMPONENT and VER are required.\n\n"; \
		printf "$(CYAN)Usage:$(NC) make set-version COMPONENT=<name> VER=<version>\n\n"; \
		printf "$(YELLOW)Components:$(NC)\n"; \
		printf "  $(GREEN)engine$(NC)    $(BLUE)→$(NC)  Tutum Engine version\n"; \
		printf "  $(GREEN)cli$(NC)       $(BLUE)→$(NC)  Tutum Admin CLI version\n"; \
		printf "  $(GREEN)plugin$(NC)    $(BLUE)→$(NC)  Docker Volume Plugin version\n"; \
		printf "  $(GREEN)postgres$(NC)  $(BLUE)→$(NC)  PostgreSQL version\n\n"; \
		printf "$(YELLOW)Example:$(NC)\n"; \
		printf "  make set-version COMPONENT=engine VER=3.3.3\n\n"; \
		exit 1; \
	fi
	@case "$(COMPONENT)" in \
		engine) \
			sed -i 's/^tutum_engine_version: .*/tutum_engine_version: "$(VER)"/' inventory/group_vars/all.yml; \
			printf "$(GREEN)✓$(NC) tutum_engine_version set to $(GREEN)$(VER)$(NC)\n";; \
		cli) \
			sed -i 's/^cli_version: .*/cli_version: "$(VER)"/' inventory/group_vars/all.yml; \
			printf "$(GREEN)✓$(NC) cli_version set to $(GREEN)$(VER)$(NC)\n";; \
		plugin) \
			sed -i 's/^plugin_version: .*/plugin_version: "$(VER)"/' inventory/group_vars/all.yml; \
			printf "$(GREEN)✓$(NC) plugin_version set to $(GREEN)$(VER)$(NC)\n";; \
		postgres) \
			sed -i 's/^postgres_version: .*/postgres_version: "$(VER)"/' inventory/group_vars/all.yml; \
			printf "$(GREEN)✓$(NC) postgres_version set to $(GREEN)$(VER)$(NC)\n";; \
		*) \
			printf "$(RED)Error:$(NC) Unknown component '$(COMPONENT)'\n"; \
			printf "Use: engine, cli, plugin, or postgres\n"; \
			exit 1;; \
	esac
