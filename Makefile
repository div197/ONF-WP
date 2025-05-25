# ONF-WP v1.0.0-Alpha - Automation Makefile
# Orange Network Foundation WordPress Development Environment

.PHONY: help dev prod stop restart logs shell wp status health setup clean build test docs

# Default target
.DEFAULT_GOAL := help

# Colors for output
CYAN := \033[0;36m
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m # No Color

# Project configuration
PROJECT_NAME := onf-wp
CLI_TOOL := ./onf-wp

help: ## Show this help message
	@echo "$(CYAN)ONF-WP v1.0.0-Alpha - Automation Commands$(NC)"
	@echo ""
	@echo "$(YELLOW)Usage:$(NC)"
	@echo "  make <command>"
	@echo ""
	@echo "$(YELLOW)Available Commands:$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(YELLOW)Examples:$(NC)"
	@echo "  make dev                 # Start development environment"
	@echo "  make wp args='plugin list' # List WordPress plugins"
	@echo "  make logs service=php    # Show PHP service logs"

setup: ## Initial project setup and configuration
	@echo "$(CYAN)🔧 Setting up ONF-WP v1.0.0-Alpha...$(NC)"
	@$(CLI_TOOL) setup

dev: ## Start development environment
	@echo "$(CYAN)🚀 Starting development environment...$(NC)"
	@$(CLI_TOOL) dev

prod: ## Start production environment
	@echo "$(CYAN)🚀 Starting production environment...$(NC)"
	@$(CLI_TOOL) prod

stop: ## Stop all services
	@echo "$(YELLOW)🛑 Stopping all services...$(NC)"
	@$(CLI_TOOL) stop

restart: ## Restart all services
	@echo "$(YELLOW)🔄 Restarting services...$(NC)"
	@$(CLI_TOOL) restart

logs: ## Show logs for service (usage: make logs service=php)
	@echo "$(CYAN)📋 Showing logs...$(NC)"
	@$(CLI_TOOL) logs $(service)

shell: ## Access service shell (usage: make shell service=php)
	@echo "$(CYAN)🐚 Accessing shell...$(NC)"
	@$(CLI_TOOL) shell $(service)

wp: ## Execute WP-CLI command (usage: make wp args='plugin list')
	@echo "$(CYAN)🔧 Executing WP-CLI...$(NC)"
	@$(CLI_TOOL) wp $(args)

status: ## Show service status
	@echo "$(CYAN)📊 Service status:$(NC)"
	@$(CLI_TOOL) status

health: ## Run health checks
	@echo "$(CYAN)🏥 Running health checks...$(NC)"
	@$(CLI_TOOL) health

clean: ## Clean up containers and volumes
	@echo "$(RED)🧹 Cleaning up...$(NC)"
	@$(CLI_TOOL) clean

build: ## Build Docker images
	@echo "$(CYAN)🔨 Building Docker images...$(NC)"
	@docker-compose -f deployments/docker-compose/docker-compose.dev.yml build

test: ## Run test suite
	@echo "$(CYAN)🧪 Running tests...$(NC)"
	@echo "Test suite coming soon in future releases..."

docs: ## Generate documentation
	@echo "$(CYAN)📚 Generating documentation...$(NC)"
	@echo "Documentation generation coming soon..."

# Development helpers
dev-reset: ## Reset development environment completely
	@echo "$(RED)🔄 Resetting development environment...$(NC)"
	@$(CLI_TOOL) clean
	@$(CLI_TOOL) setup
	@$(CLI_TOOL) dev

# Production helpers
prod-deploy: ## Deploy to production with health checks
	@echo "$(CYAN)🚀 Deploying to production...$(NC)"
	@$(CLI_TOOL) prod
	@sleep 30
	@$(CLI_TOOL) health

# Backup and restore
backup: ## Create backup
	@echo "$(CYAN)💾 Creating backup...$(NC)"
	@echo "Backup functionality coming soon..."

restore: ## Restore from backup (usage: make restore backup=filename)
	@echo "$(CYAN)📥 Restoring from backup...$(NC)"
	@echo "Restore functionality coming soon..."

# Maintenance
update: ## Update ONF-WP to latest version
	@echo "$(CYAN)⬆️ Updating ONF-WP...$(NC)"
	@git pull origin main
	@$(CLI_TOOL) setup

# Security
security-scan: ## Run security scans
	@echo "$(CYAN)🔒 Running security scans...$(NC)"
	@echo "Security scanning coming soon..."

# Performance
performance-test: ## Run performance tests
	@echo "$(CYAN)⚡ Running performance tests...$(NC)"
	@echo "Performance testing coming soon..."

# Monitoring
monitor: ## Start monitoring dashboard
	@echo "$(CYAN)📈 Starting monitoring...$(NC)"
	@echo "Monitoring dashboard coming soon..."

# Quick commands for common tasks
quick-install: setup dev ## Quick setup and start development
	@echo "$(GREEN)✅ ONF-WP is ready! Access your site at the displayed URL.$(NC)"

quick-wp-install: ## Quick WordPress installation
	@echo "$(CYAN)⚡ Quick WordPress setup...$(NC)"
	@$(CLI_TOOL) wp core download --force
	@$(CLI_TOOL) wp core install --url=localhost --title="ONF-WP Site" --admin_user=admin --admin_password=admin --admin_email=admin@example.com
	@echo "$(GREEN)✅ WordPress installed! Login: admin/admin$(NC)"

# Information
version: ## Show version information
	@echo "$(CYAN)ONF-WP v1.0.0-Alpha$(NC)"
	@echo "Revolutionary WordPress Development & Hosting Platform"
	@echo "Made in India, Made for the World 🇮🇳"

info: ## Show project information
	@echo "$(CYAN)📋 Project Information:$(NC)"
	@echo "Name: $(PROJECT_NAME)"
	@echo "Version: 1.0.0-Alpha"
	@echo "Architecture: Revolutionary SOTA Structure"
	@echo "CLI Tool: $(CLI_TOOL)"
	@echo "Repository: https://github.com/orangenetworkfoundation/ONF-WP" 