# Makefile for external project using tutum_pro.cicd collection

INVENTORY ?= inventory/hosts.yml
EXTRA_VARS ?=

.PHONY: help
help:
	@echo "Tutum Pro Deployment"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Setup:"
	@echo "  install-collection  Install tutum_pro.cicd collection from Galaxy"
	@echo "  install-from-git    Install collection from Git repository"
	@echo ""
	@echo "Deployment:"
	@echo "  deploy              Deploy all Tutum Pro components"
	@echo "  deploy-engine       Deploy only Tutum Engine"
	@echo "  deploy-plugin       Deploy only Docker plugin"
	@echo "  deploy-cli          Deploy only Admin CLI"
	@echo ""
	@echo "Management:"
	@echo "  report              Show version report"
	@echo "  uninstall           Remove all components"
	@echo "  uninstall-data      Remove all components and data"

# ==================== Setup ====================

.PHONY: install-collection
install-collection:
	ansible-galaxy collection install -r requirements.yml

.PHONY: install-from-git
install-from-git:
	ansible-galaxy collection install git+https://github.com/tutum/tutum-cicd.git

# ==================== Deployment ====================

.PHONY: deploy
deploy:
	ansible-playbook -i $(INVENTORY) site.yml $(EXTRA_VARS)

.PHONY: deploy-engine
deploy-engine:
	ansible-playbook -i $(INVENTORY) tutum_pro.cicd.engine $(EXTRA_VARS)

.PHONY: deploy-plugin
deploy-plugin:
	ansible-playbook -i $(INVENTORY) tutum_pro.cicd.plugin $(EXTRA_VARS)

.PHONY: deploy-cli
deploy-cli:
	ansible-playbook -i $(INVENTORY) tutum_pro.cicd.cli $(EXTRA_VARS)

# ==================== Management ====================

.PHONY: report
report:
	ansible-playbook -i $(INVENTORY) tutum_pro.cicd.report $(EXTRA_VARS)

.PHONY: uninstall
uninstall:
	ansible-playbook -i $(INVENTORY) tutum_pro.cicd.uninstall $(EXTRA_VARS)

.PHONY: uninstall-data
uninstall-data:
	ansible-playbook -i $(INVENTORY) tutum_pro.cicd.uninstall \
		-e tutum_engine_remove_data=true \
		-e tutum_plugin_remove_volumes=true \
		$(EXTRA_VARS)
