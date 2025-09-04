# Makefile untuk automasi task

.PHONY: help install deploy monitor clean

help: ## Tampilkan help
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

install: ## Install K3s cluster
	@echo "Installing K3s cluster..."
	./scripts/install-k3s.sh

deploy: ## Deploy semua aplikasi
	@echo "Deploying applications..."
	./scripts/deploy-apps.sh

monitor: ## Setup monitoring stack
	@echo "Setting up monitoring..."
	./scripts/setup-monitoring.sh

status: ## Check cluster status
	@echo "Cluster status:"
	sudo k3s kubectl get nodes
	@echo "\nPods status:"
	sudo k3s kubectl get pods -A

clean: ## Uninstall K3s
	@echo "Uninstalling K3s..."
	./scripts/uninstall-k3s.sh

logs: ## Tail K3s logs
	sudo journalctl -u k3s -f
