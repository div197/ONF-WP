#!/usr/bin/env bash

# ONF-WP v1.0.0-Alpha - Revolutionary Setup Script
# "Nishkaam Karma Yoga" - Intelligent Platform Detection & Setup

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

show_banner() {
    echo -e "${CYAN}"
    cat << "EOF"
🚀 ONF-WP Revolutionary Setup
"Nishkaam Karma Yoga" - Made in India, Made for the World

    ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄ 
   ▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌
   ▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀▀▀ ▐░█▀▀▀▀▀▀▀▀▀ 
   ▐░▌       ▐░▌▐░▌          ▐░▌          
   ▐░▌       ▐░▌▐░█▄▄▄▄▄▄▄▄▄ ▐░█▄▄▄▄▄▄▄▄▄ 
   ▐░▌       ▐░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌
   ▐░▌       ▐░▌▐░█▀▀▀▀▀▀▀▀▀ ▐░█▀▀▀▀▀▀▀▀▀ 
   ▐░▌       ▐░▌▐░▌          ▐░▌          
   ▐░█▄▄▄▄▄▄▄█░▌▐░▌          ▐░▌          
   ▐░░░░░░░░░░░▌▐░▌          ▐░▌          
    ▀▀▀▀▀▀▀▀▀▀▀  ▀            ▀           

Revolutionary Architecture v1.0.0-Alpha
EOF
    echo -e "${NC}"
}

# Detect platform
detect_platform() {
    local platform="unknown"
    local arch="unknown"
    
    case "$(uname -s)" in
        "Darwin")
            platform="macos"
            ;;
        "Linux")
            platform="linux"
            ;;
        "MINGW"*|"MSYS"*|"CYGWIN"*)
            platform="windows"
            ;;
        *)
            platform="unknown"
            ;;
    esac
    
    case "$(uname -m)" in
        "x86_64"|"amd64")
            arch="x64"
            ;;
        "arm64"|"aarch64")
            arch="arm64"
            ;;
        *)
            arch="unknown"
            ;;
    esac
    
    echo "$platform:$arch"
}

# Check Docker installation
check_docker() {
    echo -e "${BLUE}🐳 Checking Docker installation...${NC}"
    
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker is not installed${NC}"
        echo -e "${YELLOW}Please install Docker Desktop from: https://www.docker.com/products/docker-desktop/${NC}"
        exit 1
    fi
    
    if ! docker info >/dev/null 2>&1; then
        echo -e "${RED}❌ Docker is not running${NC}"
        echo -e "${YELLOW}Please start Docker Desktop and try again${NC}"
        exit 1
    fi
    
    local docker_version=$(docker --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1)
    echo -e "${GREEN}✅ Docker ${docker_version} is running${NC}"
    
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${RED}❌ Docker Compose is not installed${NC}"
        echo -e "${YELLOW}Please install Docker Compose${NC}"
        exit 1
    fi
    
    local compose_version=$(docker-compose --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1)
    echo -e "${GREEN}✅ Docker Compose ${compose_version} is available${NC}"
}

# Recommend optimal strategy (using platform optimizer)
recommend_strategy() {
    local platform_optimizer="$PROJECT_ROOT/scripts/setup/platform-optimizer.sh"
    
    if [[ -f "$platform_optimizer" ]]; then
        # Use the advanced platform optimizer
        bash "$platform_optimizer" analyze
        local strategy=$(bash "$platform_optimizer" strategy)
        echo "$strategy"
    else
        # Fallback to simple detection
        local platform_info=$(detect_platform)
        local platform=$(echo "$platform_info" | cut -d':' -f1)
        local arch=$(echo "$platform_info" | cut -d':' -f2)
        
        echo -e "${BLUE}🧠 Analyzing platform: ${platform} (${arch})${NC}"
        
        local recommended_strategy="docker"
        local reason=""
        
        case "$platform" in
            "windows")
                recommended_strategy="docker"
                reason="Docker volumes provide best performance on Windows with Docker Desktop"
                ;;
            "macos")
                recommended_strategy="docker"
                reason="Docker volumes eliminate slow bind mount performance on macOS"
                ;;
            "linux")
                recommended_strategy="hybrid"
                reason="Linux can efficiently handle hybrid approach with selective bind mounts"
                ;;
            *)
                recommended_strategy="docker"
                reason="Docker volumes provide maximum compatibility"
                ;;
        esac
        
        echo -e "${CYAN}💡 Recommended strategy: ${WHITE}${recommended_strategy}${NC}"
        echo -e "${CYAN}📋 Reason: ${reason}${NC}"
        echo ""
        
        echo "$recommended_strategy"
    fi
}

# Interactive project configuration
configure_project() {
    echo -e "${BLUE}📝 Project Configuration${NC}"
    echo ""
    
    # Project name
    local default_project_name=$(basename "$PROJECT_ROOT" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g')
    read -p "$(echo -e "${CYAN}Project name [${default_project_name}]: ${NC}")" project_name
    project_name="${project_name:-$default_project_name}"
    
    # Domain
    local default_domain="${project_name}.onfwp.test"
    read -p "$(echo -e "${CYAN}Project domain [${default_domain}]: ${NC}")" project_domain
    project_domain="${project_domain:-$default_domain}"
    
    # Ports
    local default_http_port="8000"
    read -p "$(echo -e "${CYAN}HTTP port [${default_http_port}]: ${NC}")" http_port
    http_port="${http_port:-$default_http_port}"
    
    local default_https_port="8443"
    read -p "$(echo -e "${CYAN}HTTPS port [${default_https_port}]: ${NC}")" https_port
    https_port="${https_port:-$default_https_port}"
    
    local default_webui_port="8081"
    read -p "$(echo -e "${CYAN}Traefik WebUI port [${default_webui_port}]: ${NC}")" webui_port
    webui_port="${webui_port:-$default_webui_port}"
    
    # Strategy
    local recommended_strategy=$(recommend_strategy)
    echo -e "${YELLOW}Volume strategies available:${NC}"
    echo -e "  ${GREEN}docker${NC}    - 100% Docker volumes (best performance & portability)"
    echo -e "  ${GREEN}hybrid${NC}    - Docker volumes + development bind mounts"
    echo -e "  ${GREEN}bindmount${NC} - Traditional bind mounts (legacy)"
    echo ""
    read -p "$(echo -e "${CYAN}Volume strategy [${recommended_strategy}]: ${NC}")" volume_strategy
    volume_strategy="${volume_strategy:-$recommended_strategy}"
    
    # Validate strategy
    if [[ ! "$volume_strategy" =~ ^(docker|hybrid|bindmount)$ ]]; then
        echo -e "${RED}❌ Invalid strategy. Using recommended: ${recommended_strategy}${NC}"
        volume_strategy="$recommended_strategy"
    fi
    
    # Store configuration
    cat > "$PROJECT_ROOT/.env" << EOF
# ONF-WP v1.0.0-Alpha-Docker - Revolutionary Configuration
# Generated on $(date)

# ========================================================================
# 🚀 REVOLUTIONARY VOLUME STRATEGY CONFIGURATION
# ========================================================================

ONF_VOLUME_STRATEGY=${volume_strategy}
ONF_DEV_THEMES_SYNC=true
ONF_DEV_PLUGINS_SYNC=true
ONF_DOCKER_PLATFORM_AUTO=true
ONF_VOLUME_CONSISTENCY=cached

# ========================================================================
# 📁 PROJECT CONFIGURATION
# ========================================================================

COMPOSE_PROJECT_NAME=${project_name}
PROJECT_DOMAIN=${project_domain}

# WordPress Configuration
WORDPRESS_SITE_TITLE="${project_name^} Site"
WORDPRESS_ADMIN_USER=admin
WORDPRESS_ADMIN_EMAIL=admin@${project_domain}

# ========================================================================
# 🔧 DOCKER & NETWORKING CONFIGURATION  
# ========================================================================

TRAEFIK_HTTP_PORT=${http_port}
TRAEFIK_HTTPS_PORT=${https_port}
TRAEFIK_WEBUI_PORT=${webui_port}
DOCKER_SUBNET_THIRD_OCTET=20

# ========================================================================
# 🎯 VOLUME MANAGEMENT CONFIGURATION
# ========================================================================

ONF_VOLUME_PREFIX=${project_name}
ONF_VOLUME_DRIVER=local
ONF_BACKUP_STRATEGY=incremental
ONF_BACKUP_RETENTION=7
ONF_BACKUP_COMPRESSION=true

# ========================================================================
# 🚀 PERFORMANCE OPTIMIZATION
# ========================================================================

ONF_VOLUME_NOCOPY=false
ONF_VOLUME_CACHE_DRIVER=native
ONF_PHP_MEMORY_LIMIT=512M
ONF_PHP_MAX_EXECUTION_TIME=300
ONF_NGINX_WORKER_PROCESSES=auto

# ========================================================================
# 🔒 SECURITY & PRODUCTION OPTIONS
# ========================================================================

WP_ENV=development
WP_DEBUG=true
WP_DEBUG_LOG=true
WP_DEBUG_DISPLAY=false

DB_PASSWORD=secure_dev_password_${project_name}
DB_ROOT_PASSWORD=secure_dev_root_password_${project_name}

ONF_SSL_ENABLED=true
ONF_SSL_PROVIDER=traefik

# ========================================================================
# 🌐 ADVANCED FEATURES
# ========================================================================

ONF_CLOUDFLARE_ENABLED=false
ONF_MULTISITE_ENABLED=false
ONF_MONITORING_ENABLED=true
ONF_LOGGING_LEVEL=info
ONF_METRICS_ENABLED=true

ONF_XDEBUG_ENABLED=false
ONF_PROFILER_ENABLED=false
ONF_MAIL_CATCHER_ENABLED=true

# ========================================================================
# 🎨 REVOLUTIONARY FEATURES
# ========================================================================

ONF_AI_OPTIMIZATION=false
ONF_AUTO_SCALING=false
ONF_INTELLIGENT_CACHING=true

ONF_VERSION=1.0.0-Alpha-Docker
ONF_ARCHITECTURE=revolutionary-volumes
ONF_PHILOSOPHY="Nishkaam Karma Yoga"
EOF
    
    echo -e "${GREEN}✅ Configuration saved to .env${NC}"
    echo ""
    echo -e "${CYAN}📋 Your Configuration:${NC}"
    echo -e "   ${WHITE}Project:${NC} ${project_name}"
    echo -e "   ${WHITE}Domain:${NC} https://${project_domain}"
    echo -e "   ${WHITE}Strategy:${NC} ${volume_strategy}"
    echo -e "   ${WHITE}Ports:${NC} HTTP:${http_port}, HTTPS:${https_port}, WebUI:${webui_port}"
    echo ""
}

# Setup docker-compose based on strategy
setup_docker_compose() {
    local strategy="${1:-docker}"
    
    echo -e "${BLUE}🔧 Setting up Docker Compose for ${strategy} strategy...${NC}"
    
    local compose_source=""
    case "$strategy" in
        "docker")
            compose_source="$PROJECT_ROOT/configs/volume-strategies/docker-only.yml"
            ;;
        "hybrid")
            compose_source="$PROJECT_ROOT/configs/volume-strategies/hybrid.yml"
            ;;
        "bindmount")
            compose_source="$PROJECT_ROOT/deployments/docker-compose/docker-compose.dev.yml"
            ;;
        *)
            echo -e "${RED}❌ Unknown strategy: $strategy${NC}"
            exit 1
            ;;
    esac
    
    if [[ -f "$compose_source" ]]; then
        cp "$compose_source" "$PROJECT_ROOT/docker-compose.yml"
        echo -e "${GREEN}✅ Docker Compose configured for ${strategy} strategy${NC}"
    else
        echo -e "${RED}❌ Strategy file not found: $compose_source${NC}"
        exit 1
    fi
}

# Create necessary directories
create_directories() {
    echo -e "${BLUE}📁 Creating project directories...${NC}"
    
    local dirs=(
        "development/themes"
        "development/plugins"
        "development/uploads"
        "backups/full"
        "backups/themes"
        "backups/plugins"
        "backups/migration"
        "storage/logs"
    )
    
    for dir in "${dirs[@]}"; do
        mkdir -p "$PROJECT_ROOT/$dir"
        echo -e "   ${GREEN}✅ Created: $dir${NC}"
    done
    
    # Create .gitkeep files for empty directories
    find "$PROJECT_ROOT/development" -type d -empty -exec touch {}/.gitkeep \;
    find "$PROJECT_ROOT/backups" -type d -empty -exec touch {}/.gitkeep \;
}

# Set permissions
set_permissions() {
    echo -e "${BLUE}🔒 Setting up permissions...${NC}"
    
    # Make scripts executable
    chmod +x "$PROJECT_ROOT/onf-wp" 2>/dev/null || true
    chmod +x "$PROJECT_ROOT/scripts/volume-management/"*.sh 2>/dev/null || true
    chmod +x "$PROJECT_ROOT/scripts/setup/"*.sh 2>/dev/null || true
    chmod +x "$PROJECT_ROOT/scripts/deployment/"*.sh 2>/dev/null || true
    chmod +x "$PROJECT_ROOT/scripts/maintenance/"*.sh 2>/dev/null || true
    chmod +x "$PROJECT_ROOT/scripts/development/"*.sh 2>/dev/null || true
    
    echo -e "${GREEN}✅ Permissions set${NC}"
}

# Apply platform optimizations
apply_platform_optimizations() {
    echo -e "${BLUE}🚀 Applying platform-specific optimizations...${NC}"
    
    local platform_optimizer="$PROJECT_ROOT/scripts/setup/platform-optimizer.sh"
    
    if [[ -f "$platform_optimizer" ]]; then
        bash "$platform_optimizer" optimize
        echo -e "${GREEN}✅ Platform optimizations applied${NC}"
    else
        echo -e "${YELLOW}⚠️ Platform optimizer not found, skipping optimizations${NC}"
    fi
}

# Show next steps
show_next_steps() {
    local project_name="${COMPOSE_PROJECT_NAME:-onfwp}"
    local project_domain="${PROJECT_DOMAIN:-localhost}"
    local https_port="${TRAEFIK_HTTPS_PORT:-8443}"
    local webui_port="${TRAEFIK_WEBUI_PORT:-8081}"
    
    echo -e "${GREEN}🎉 ONF-WP Revolutionary Setup Complete!${NC}"
    echo ""
    echo -e "${CYAN}🚀 Next Steps:${NC}"
    echo ""
    echo -e "${WHITE}1. Start your WordPress environment:${NC}"
    echo -e "   ${GREEN}./onf-wp dev${NC}"
    echo ""
    echo -e "${WHITE}2. Access your site:${NC}"
    echo -e "   ${GREEN}https://${project_domain}${NC}"
    if [[ "$https_port" != "443" ]]; then
        echo -e "   ${YELLOW}Note: Use port ${https_port} if not using standard HTTPS${NC}"
    fi
    echo ""
    echo -e "${WHITE}3. Access Traefik Dashboard:${NC}"
    echo -e "   ${GREEN}http://localhost:${webui_port}${NC}"
    echo ""
    echo -e "${WHITE}4. Database Management (Adminer):${NC}"
    echo -e "   ${GREEN}http://db.${project_domain}${NC}"
    echo ""
    echo -e "${CYAN}🎯 Revolutionary Features Available:${NC}"
    echo -e "   ${GREEN}./onf-wp volume status${NC}      # Check volume status"
    echo -e "   ${GREEN}./onf-wp volume sync themes${NC}  # Sync themes for development"
    echo -e "   ${GREEN}./onf-wp volume export full${NC}  # Export complete WordPress"
    echo -e "   ${GREEN}./onf-wp wp plugin list${NC}     # Use WP-CLI"
    echo ""
    echo -e "${PURPLE}💡 Pro Tips:${NC}"
    echo -e "   • Copy this folder anywhere and run ${GREEN}./onf-wp dev${NC} - it just works!"
    echo -e "   • Use ${GREEN}./onf-wp help${NC} to see all available commands"
    echo -e "   • Docker volumes provide best performance across all platforms"
    echo ""
    echo -e "${CYAN}Made in India, Made for the World! 🇮🇳${NC}"
    echo -e "${YELLOW}\"Nishkaam Karma Yoga\" - Selfless action for the WordPress community${NC}"
    echo ""
}

# Main setup function
main() {
    show_banner
    
    echo -e "${BLUE}🔍 Starting revolutionary ONF-WP setup...${NC}"
    echo ""
    
    # Check prerequisites
    check_docker
    echo ""
    
    # Configure project
    configure_project
    
    # Source the new .env file
    source "$PROJECT_ROOT/.env"
    
    # Setup docker-compose
    setup_docker_compose "$ONF_VOLUME_STRATEGY"
    
    # Create directories
    create_directories
    
    # Set permissions
    set_permissions
    
    # Apply platform optimizations
    apply_platform_optimizations
    
    echo ""
    show_next_steps
}

# Run setup
main "$@" 