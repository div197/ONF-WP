#!/bin/bash
# ONF-WP v1.0.5 - Production Deployment Script
# Revolutionary WordPress hosting deployment assistant

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# ONF-WP Logo
print_logo() {
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║                    🍊 ONF-WP v1.0.5 🍊                       ║"
    echo "║              Production Deployment Assistant                  ║"
    echo "║         Revolutionizing WordPress Hosting Since 2025         ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_title() { echo -e "\n${PURPLE}=== $1 ===${NC}"; }

# Check prerequisites
check_prerequisites() {
    log_title "Checking Prerequisites"
    
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker is not running. Please start Docker Desktop."
        exit 1
    fi
    log_success "Docker is running"
    
    if ! command -v docker-compose >/dev/null 2>&1; then
        log_error "docker-compose is not installed."
        exit 1
    fi
    log_success "docker-compose is available"
}

# Quick production deploy
quick_production_deploy() {
    log_title "Quick Production Deployment"
    
    log_info "Deploying ONF-WP in production mode with:"
    echo "  ✅ Redis caching enabled"
    echo "  ✅ OpCache optimized" 
    echo "  ✅ Security hardening"
    echo "  ✅ SSL/TLS support"
    echo "  ✅ Performance monitoring"
    
    read -p "Continue? (y/N): " confirm
    if [[ $confirm != [yY] ]]; then
        return
    fi
    
    log_info "Stopping existing containers..."
    docker-compose down -v 2>/dev/null || true
    
    log_info "Building production containers..."
    docker-compose -f docker-compose.prod.yml build --no-cache
    
    log_info "Starting production environment..."
    docker-compose -f docker-compose.prod.yml up -d
    
    log_info "Waiting for services..."
    sleep 30
    
    log_success "🎉 Production deployment completed!"
    log_info "Site: https://${PROJECT_DOMAIN:-abcsteps.com}"
}

# Main menu
show_main_menu() {
    echo -e "\n${CYAN}Select deployment mode:${NC}"
    echo "1) 🚀 Quick Production Deploy"
    echo "2) 📊 System Health Check" 
    echo "3) 🧹 Clean Environment"
    echo "4) 📋 View Status"
    echo "0) 🚪 Exit"
    echo ""
    read -p "Choice (0-4): " choice
}

# Main execution
main() {
    print_logo
    check_prerequisites
    
    # Source environment if available
    [[ -f ".env" ]] && source .env
    [[ -f ".env.prod" ]] && source .env.prod
    
    while true; do
        show_main_menu
        
        case $choice in
            1) quick_production_deploy ;;
            2) docker-compose -f docker-compose.prod.yml ps ;;
            3) 
                read -p "Remove all data? (y/N): " confirm
                [[ $confirm == [yY] ]] && docker-compose -f docker-compose.prod.yml down -v
                ;;
            4) docker-compose -f docker-compose.prod.yml logs --tail=20 ;;
            0) log_info "Goodbye! 🍊"; exit 0 ;;
            *) log_error "Invalid option" ;;
        esac
        
        read -p "Press Enter..."
    done
}

main "$@" 