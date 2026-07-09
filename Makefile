.PHONY: help setup init user start stop restart status logs upgrade clean test

# Default compose file
COMPOSE_FILE := docker-compose.prod.yml
COMPOSE := docker compose -f $(COMPOSE_FILE)

help: ## Show this help message
	@echo "Postal Management Commands"
	@echo "============================"
	@echo
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

setup: ## Initial setup - create configuration files
	@./scripts/setup.sh

init: ## Initialize database (run after setup)
	@./scripts/initialize.sh

user: ## Create admin user
	@./scripts/make-user.sh

start: ## Start all services
	@echo "Starting Postal services..."
	@$(COMPOSE) up -d
	@echo "Done! Check status with: make status"

stop: ## Stop all services
	@echo "Stopping Postal services..."
	@$(COMPOSE) down
	@echo "Services stopped"

restart: ## Restart all services
	@echo "Restarting Postal services..."
	@$(COMPOSE) restart
	@echo "Services restarted"

status: ## Show service status
	@./scripts/status.sh

logs: ## Show logs (use 'make logs SERVICE=web' for specific service)
	@$(COMPOSE) logs -f $(SERVICE)

ps: ## Show running containers
	@$(COMPOSE) ps

pull: ## Pull latest images
	@echo "Pulling latest images..."
	@$(COMPOSE) pull
	@echo "Done!"

upgrade: ## Upgrade to specific version (use 'make upgrade VERSION=3.3.4')
	@if [ -z "$(VERSION)" ]; then \
		echo "Error: VERSION required. Usage: make upgrade VERSION=3.3.4"; \
		exit 1; \
	fi
	@./scripts/upgrade.sh $(VERSION)

console: ## Open Rails console
	@$(COMPOSE) run --rm runner postal console

version: ## Show Postal version
	@$(COMPOSE) run --rm runner postal version

dkim: ## Show default DKIM record
	@$(COMPOSE) run --rm runner postal default-dkim-record

bash: ## Access bash in a service (use 'make bash SERVICE=web')
	@if [ -z "$(SERVICE)" ]; then \
		echo "Error: SERVICE required. Usage: make bash SERVICE=web"; \
		exit 1; \
	fi
	@$(COMPOSE) exec $(SERVICE) bash

db: ## Access MariaDB console
	@$(COMPOSE) exec mariadb mysql -u root -ppostal postal

backup-db: ## Backup database to backup.sql
	@echo "Backing up database..."
	@$(COMPOSE) exec mariadb mysqldump -u root -ppostal --all-databases > backup-$$(date +%Y%m%d-%H%M%S).sql
	@echo "Backup complete!"

backup-config: ## Backup configuration files
	@echo "Backing up configuration..."
	@tar -czf config-backup-$$(date +%Y%m%d-%H%M%S).tar.gz config/
	@echo "Backup complete!"

clean: ## Stop and remove all containers, networks, and volumes (⚠️  DESTROYS DATA)
	@echo "⚠️  WARNING: This will destroy all data!"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		$(COMPOSE) down -v; \
		echo "Cleaned!"; \
	else \
		echo "Cancelled."; \
	fi

dev: ## Start in development mode
	@docker compose -f docker-compose.dev.yml up -d

dev-logs: ## Show development logs
	@docker compose -f docker-compose.dev.yml logs -f

dev-stop: ## Stop development environment
	@docker compose -f docker-compose.dev.yml down

CI_COMPOSE := docker compose -f docker/ci/docker-compose.yml

test: ## Run the full test suite in a self-contained container (same as CI)
	@$(CI_COMPOSE) run --build --rm test; rc=$$?; $(CI_COMPOSE) down -v >/dev/null 2>&1; exit $$rc
