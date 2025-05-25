#!/usr/bin/env bash

# ONF-WP v1.0.0-Alpha - Comprehensive Health Check
# "Nishkaam Karma Yoga" - Complete System Validation

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
source "$PROJECT_ROOT/.env" 2>/dev/null || true

COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME:-onfwp}"
PROJECT_DOMAIN="${PROJECT_DOMAIN:-localhost}"

# Health check results
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNING_CHECKS=0

show_banner() {
    echo -e "${CYAN}"
    cat << "EOF"
🏥 ONF-WP Health Check System
"Nishkaam Karma Yoga" - Complete System Validation

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

Revolutionary Health Check v1.0.0-Alpha
EOF
    echo -e "${NC}"
}

# Check function wrapper
check() {
    local name="$1"
    local command="$2"
    local expected_result="${3:-0}"
    
    ((TOTAL_CHECKS++))
    
    echo -ne "${BLUE}Checking $name...${NC} "
    
    if eval "$command" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ PASS${NC}"
        ((PASSED_CHECKS++))
        return 0
    else
        echo -e "${RED}❌ FAIL${NC}"
        ((FAILED_CHECKS++))
        return 1
    fi
}

# Warning check function
check_warn() {
    local name="$1"
    local command="$2"
    
    ((TOTAL_CHECKS++))
    
    echo -ne "${BLUE}Checking $name...${NC} "
    
    if eval "$command" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ PASS${NC}"
        ((PASSED_CHECKS++))
        return 0
    else
        echo -e "${YELLOW}⚠️ WARNING${NC}"
        ((WARNING_CHECKS++))
        return 1
    fi
}

# System requirements check
check_system_requirements() {
    echo -e "${CYAN}🔍 System Requirements Check${NC}"
    echo ""
    
    # Docker installation
    check "Docker installed" "command -v docker"
    check "Docker running" "docker info"
    check "Docker Compose installed" "command -v docker-compose"
    
    # Docker version check
    local docker_version=$(docker --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1)
    local compose_version=$(docker-compose --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1)
    
    echo -e "${WHITE}Docker version:${NC} $docker_version"
    echo -e "${WHITE}Docker Compose version:${NC} $compose_version"
    
    # Memory check
    local available_memory=""
    case "$(uname -s)" in
        "Linux")
            available_memory=$(free -m | awk 'NR==2{printf "%.1f", $7/1024}')
            echo -e "${WHITE}Available memory:${NC} ${available_memory}GB"
            ;;
        "Darwin")
            available_memory=$(vm_stat | perl -ne '/free:\s+(\d+)/ and $free=$1; /speculative:\s+(\d+)/ and $spec=$1; END {printf "%.1f", ($free+$spec)*4096/1024/1024/1024}')
            echo -e "${WHITE}Available memory:${NC} ${available_memory}GB"
            ;;
    esac
    
    echo ""
}

# Project structure check
check_project_structure() {
    echo -e "${CYAN}📁 Project Structure Check${NC}"
    echo ""
    
    # Essential files
    check "onf-wp CLI exists" "test -f $PROJECT_ROOT/onf-wp"
    check "onf-wp CLI executable" "test -x $PROJECT_ROOT/onf-wp"
    check ".env file exists" "test -f $PROJECT_ROOT/.env"
    check "Docker compose strategy file" "test -f $PROJECT_ROOT/docker-compose.yml"
    
    # Essential directories
    check "Build directory" "test -d $PROJECT_ROOT/build"
    check "Scripts directory" "test -d $PROJECT_ROOT/scripts"
    check "Configs directory" "test -d $PROJECT_ROOT/configs"
    check "Development directory" "test -d $PROJECT_ROOT/development"
    check "Backups directory" "test -d $PROJECT_ROOT/backups"
    
    # Volume strategy files
    check "Docker-only strategy" "test -f $PROJECT_ROOT/configs/volume-strategies/docker-only.yml"
    check "Hybrid strategy" "test -f $PROJECT_ROOT/configs/volume-strategies/hybrid.yml"
    check "Volume manager script" "test -f $PROJECT_ROOT/scripts/volume-management/volume-manager.sh"
    
    echo ""
}

# Environment configuration check
check_environment() {
    echo -e "${CYAN}⚙️ Environment Configuration Check${NC}"
    echo ""
    
    # Essential environment variables
    check "COMPOSE_PROJECT_NAME set" "test -n '${COMPOSE_PROJECT_NAME:-}'"
    check "PROJECT_DOMAIN set" "test -n '${PROJECT_DOMAIN:-}'"
    check "ONF_VOLUME_STRATEGY set" "test -n '${ONF_VOLUME_STRATEGY:-}'"
    
    # Volume strategy validation
    if [[ -n "${ONF_VOLUME_STRATEGY:-}" ]]; then
        case "$ONF_VOLUME_STRATEGY" in
            "docker"|"hybrid"|"bindmount")
                echo -e "${GREEN}✅ Valid volume strategy: $ONF_VOLUME_STRATEGY${NC}"
                ;;
            *)
                echo -e "${RED}❌ Invalid volume strategy: $ONF_VOLUME_STRATEGY${NC}"
                ((FAILED_CHECKS++))
                ;;
        esac
    fi
    
    # Port configuration
    echo -e "${WHITE}HTTP Port:${NC} ${TRAEFIK_HTTP_PORT:-8000}"
    echo -e "${WHITE}HTTPS Port:${NC} ${TRAEFIK_HTTPS_PORT:-8443}"
    echo -e "${WHITE}WebUI Port:${NC} ${TRAEFIK_WEBUI_PORT:-8081}"
    
    echo ""
}

# Docker services check
check_docker_services() {
    echo -e "${CYAN}🐳 Docker Services Check${NC}"
    echo ""
    
    # Check if services are defined
    local compose_file="$PROJECT_ROOT/docker-compose.yml"
    if [[ ! -f "$compose_file" ]]; then
        echo -e "${RED}❌ docker-compose.yml not found${NC}"
        ((FAILED_CHECKS++))
        return
    fi
    
    # Check for essential services
    local services=("php" "nginx" "mariadb" "redis" "traefik")
    for service in "${services[@]}"; do
        if grep -q "^  $service:" "$compose_file"; then
            echo -e "${GREEN}✅ Service defined: $service${NC}"
        else
            echo -e "${RED}❌ Service missing: $service${NC}"
            ((FAILED_CHECKS++))
        fi
    done
    
    # Check running services
    echo ""
    echo -e "${BLUE}Running Services:${NC}"
    
    local running_services=$(docker-compose ps --services --filter "status=running" 2>/dev/null || echo "")
    if [[ -n "$running_services" ]]; then
        for service in $running_services; do
            local status=$(docker-compose ps "$service" | tail -n +3 | awk '{print $4}')
            echo -e "${GREEN}✅ $service: $status${NC}"
        done
    else
        echo -e "${YELLOW}⚠️ No services currently running${NC}"
        ((WARNING_CHECKS++))
    fi
    
    echo ""
}

# Volume health check
check_volumes() {
    echo -e "${CYAN}💾 Docker Volumes Check${NC}"
    echo ""
    
    local volumes=$(docker volume ls --filter name="${COMPOSE_PROJECT_NAME}" --format "{{.Name}}" 2>/dev/null || echo "")
    
    if [[ -n "$volumes" ]]; then
        echo -e "${GREEN}✅ Project volumes found:${NC}"
        for volume in $volumes; do
            local size=$(docker system df -v 2>/dev/null | grep "$volume" | awk '{print $3}' || echo "Unknown")
            echo -e "${WHITE}   📁 $volume${NC} ($size)"
            
            # Check volume accessibility
            if docker volume inspect "$volume" >/dev/null 2>&1; then
                echo -e "${GREEN}      ✅ Accessible${NC}"
            else
                echo -e "${RED}      ❌ Not accessible${NC}"
                ((FAILED_CHECKS++))
            fi
        done
    else
        echo -e "${YELLOW}⚠️ No Docker volumes found for project: $COMPOSE_PROJECT_NAME${NC}"
        ((WARNING_CHECKS++))
    fi
    
    echo ""
}

# Network connectivity check
check_network() {
    echo -e "${CYAN}🌐 Network Connectivity Check${NC}"
    echo ""
    
    # Check Docker networks
    local networks=$(docker network ls --filter name="${COMPOSE_PROJECT_NAME}" --format "{{.Name}}" 2>/dev/null || echo "")
    
    if [[ -n "$networks" ]]; then
        echo -e "${GREEN}✅ Project networks found:${NC}"
        for network in $networks; do
            echo -e "${WHITE}   🌐 $network${NC}"
        done
    else
        echo -e "${YELLOW}⚠️ No Docker networks found for project${NC}"
        ((WARNING_CHECKS++))
    fi
    
    # Check port availability
    local ports=("${TRAEFIK_HTTP_PORT:-8000}" "${TRAEFIK_HTTPS_PORT:-8443}" "${TRAEFIK_WEBUI_PORT:-8081}")
    
    echo ""
    echo -e "${BLUE}Port Availability:${NC}"
    for port in "${ports[@]}"; do
        if netstat -tuln 2>/dev/null | grep ":$port " >/dev/null; then
            echo -e "${GREEN}✅ Port $port: In use (likely by ONF-WP)${NC}"
        else
            echo -e "${YELLOW}⚠️ Port $port: Available${NC}"
        fi
    done
    
    echo ""
}

# WordPress check
check_wordpress() {
    echo -e "${CYAN}📝 WordPress Check${NC}"
    echo ""
    
    # Check if WordPress is accessible
    local wp_url="https://${PROJECT_DOMAIN}"
    local http_port="${TRAEFIK_HTTPS_PORT:-8443}"
    
    if [[ "$http_port" != "443" ]]; then
        wp_url="https://${PROJECT_DOMAIN}:${http_port}"
    fi
    
    echo -e "${BLUE}Testing WordPress accessibility...${NC}"
    echo -e "${WHITE}URL: $wp_url${NC}"
    
    # Test with curl (allow self-signed certificates)
    if curl -k -s --connect-timeout 10 --max-time 30 "$wp_url" | grep -qi "wordpress\|wp-content" 2>/dev/null; then
        echo -e "${GREEN}✅ WordPress is accessible${NC}"
    else
        echo -e "${YELLOW}⚠️ WordPress may not be accessible (this is normal if services aren't running)${NC}"
        ((WARNING_CHECKS++))
    fi
    
    # Check WP-CLI functionality
    echo ""
    echo -e "${BLUE}Testing WP-CLI...${NC}"
    
    if docker-compose exec -T wpcli wp --info >/dev/null 2>&1; then
        echo -e "${GREEN}✅ WP-CLI is functional${NC}"
    else
        echo -e "${YELLOW}⚠️ WP-CLI not accessible (services may not be running)${NC}"
        ((WARNING_CHECKS++))
    fi
    
    echo ""
}

# Performance check
check_performance() {
    echo -e "${CYAN}⚡ Performance Check${NC}"
    echo ""
    
    # Docker system info
    local docker_info=$(docker system df 2>/dev/null || echo "Unable to get Docker system info")
    echo -e "${WHITE}Docker System Usage:${NC}"
    echo "$docker_info"
    
    echo ""
    
    # Platform-specific checks
    local platform_optimizer="$PROJECT_ROOT/scripts/setup/platform-optimizer.sh"
    if [[ -f "$platform_optimizer" ]]; then
        echo -e "${BLUE}Platform Analysis:${NC}"
        bash "$platform_optimizer" analyze
    fi
    
    echo ""
}

# Security check
check_security() {
    echo -e "${CYAN}🔒 Security Check${NC}"
    echo ""
    
    # Check for exposed ports
    check_warn "No direct database exposure" "! netstat -tuln 2>/dev/null | grep ':3306 '"
    
    # Check for secure passwords
    if [[ -n "${DB_PASSWORD:-}" ]] && [[ "${DB_PASSWORD}" != *"default"* ]] && [[ "${DB_PASSWORD}" != *"password"* ]]; then
        echo -e "${GREEN}✅ Database password appears secure${NC}"
    else
        echo -e "${YELLOW}⚠️ Consider using a more secure database password${NC}"
        ((WARNING_CHECKS++))
    fi
    
    # Check file permissions
    if [[ -f "$PROJECT_ROOT/.env" ]]; then
        local env_perms=$(stat -c "%a" "$PROJECT_ROOT/.env" 2>/dev/null || stat -f "%A" "$PROJECT_ROOT/.env" 2>/dev/null || echo "unknown")
        if [[ "$env_perms" == "600" ]] || [[ "$env_perms" == "644" ]]; then
            echo -e "${GREEN}✅ .env file permissions: $env_perms${NC}"
        else
            echo -e "${YELLOW}⚠️ .env file permissions: $env_perms (consider 600 for better security)${NC}"
            ((WARNING_CHECKS++))
        fi
    fi
    
    echo ""
}

# Generate health report
generate_report() {
    echo -e "${CYAN}📊 Health Check Summary${NC}"
    echo ""
    
    local total_score=$((PASSED_CHECKS * 100 / TOTAL_CHECKS))
    
    echo -e "${WHITE}Total Checks:${NC} $TOTAL_CHECKS"
    echo -e "${GREEN}Passed:${NC} $PASSED_CHECKS"
    echo -e "${RED}Failed:${NC} $FAILED_CHECKS"
    echo -e "${YELLOW}Warnings:${NC} $WARNING_CHECKS"
    echo ""
    
    if [[ $FAILED_CHECKS -eq 0 ]]; then
        if [[ $WARNING_CHECKS -eq 0 ]]; then
            echo -e "${GREEN}🎉 Perfect Health Score: 100%${NC}"
            echo -e "${GREEN}Your ONF-WP installation is in perfect condition!${NC}"
        else
            echo -e "${YELLOW}🌟 Good Health Score: ${total_score}%${NC}"
            echo -e "${YELLOW}Your ONF-WP installation is healthy with some minor recommendations.${NC}"
        fi
    else
        echo -e "${RED}⚠️ Health Score: ${total_score}%${NC}"
        echo -e "${RED}Your ONF-WP installation has some issues that need attention.${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}Next Steps:${NC}"
    
    if [[ $FAILED_CHECKS -gt 0 ]]; then
        echo -e "${RED}🔧 Fix the failed checks above${NC}"
        echo -e "${BLUE}   Run: ./onf-wp setup (if initial setup needed)${NC}"
        echo -e "${BLUE}   Run: ./onf-wp dev (to start services)${NC}"
    fi
    
    if [[ $WARNING_CHECKS -gt 0 ]]; then
        echo -e "${YELLOW}💡 Review warnings for optimization opportunities${NC}"
    fi
    
    echo -e "${GREEN}📋 Run: ./onf-wp help (for available commands)${NC}"
    echo -e "${GREEN}🔍 Run: ./onf-wp volume status (for volume information)${NC}"
    
    echo ""
    echo -e "${PURPLE}Made in India, Made for the World! 🇮🇳${NC}"
    echo -e "${CYAN}\"Nishkaam Karma Yoga\" - Selfless action for excellence${NC}"
}

# Main function
main() {
    show_banner
    
    echo -e "${BLUE}🔍 Starting comprehensive health check...${NC}"
    echo ""
    
    check_system_requirements
    check_project_structure
    check_environment
    check_docker_services
    check_volumes
    check_network
    check_wordpress
    check_performance
    check_security
    
    generate_report
}

# Execute main function
main "$@" 