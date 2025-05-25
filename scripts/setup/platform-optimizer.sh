#!/usr/bin/env bash

# ONF-WP v1.0.0-Alpha - Platform Optimizer
# "Nishkaam Karma Yoga" - Platform-Specific Performance Optimization

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

# Platform Detection
detect_platform() {
    local platform="unknown"
    local arch="unknown"
    local docker_type="unknown"
    
    # Detect OS
    case "$(uname -s)" in
        "Darwin")
            platform="macos"
            ;;
        "Linux")
            platform="linux"
            # Check if it's WSL
            if grep -qi microsoft /proc/version 2>/dev/null; then
                platform="wsl"
            fi
            ;;
        "MINGW"*|"MSYS"*|"CYGWIN"*)
            platform="windows"
            ;;
        *)
            platform="unknown"
            ;;
    esac
    
    # Detect Architecture
    case "$(uname -m)" in
        "x86_64"|"amd64")
            arch="x64"
            ;;
        "arm64"|"aarch64")
            arch="arm64"
            ;;
        "i386"|"i686")
            arch="x86"
            ;;
        *)
            arch="unknown"
            ;;
    esac
    
    # Detect Docker type
    if command -v docker &> /dev/null; then
        if docker info 2>/dev/null | grep -qi "docker desktop"; then
            docker_type="desktop"
        elif docker info 2>/dev/null | grep -qi "podman"; then
            docker_type="podman"
        elif docker info 2>/dev/null | grep -qi "colima"; then
            docker_type="colima"
        else
            docker_type="native"
        fi
    fi
    
    echo "$platform:$arch:$docker_type"
}

# Get optimal volume strategy
get_optimal_strategy() {
    local platform_info=$(detect_platform)
    local platform=$(echo "$platform_info" | cut -d':' -f1)
    local arch=$(echo "$platform_info" | cut -d':' -f2)
    local docker_type=$(echo "$platform_info" | cut -d':' -f3)
    
    local strategy="docker"
    local reason=""
    
    case "$platform" in
        "windows")
            strategy="docker"
            reason="Docker volumes provide best performance on Windows (eliminates slow bind mounts)"
            ;;
        "macos")
            strategy="docker"
            reason="Docker volumes bypass slow macOS bind mount virtualization layer"
            ;;
        "wsl")
            strategy="hybrid"
            reason="WSL benefits from hybrid approach with Linux-native bind mounts"
            ;;
        "linux")
            if [[ "$docker_type" == "desktop" ]]; then
                strategy="docker"
                reason="Docker Desktop on Linux benefits from volume strategy"
            else
                strategy="hybrid"
                reason="Native Linux Docker can efficiently handle hybrid bind mounts"
            fi
            ;;
        *)
            strategy="docker"
            reason="Docker volumes provide maximum compatibility for unknown platforms"
            ;;
    esac
    
    echo "$strategy:$reason"
}

# Generate platform-specific optimizations
generate_optimizations() {
    local platform_info=$(detect_platform)
    local platform=$(echo "$platform_info" | cut -d':' -f1)
    local arch=$(echo "$platform_info" | cut -d':' -f2)
    local docker_type=$(echo "$platform_info" | cut -d':' -f3)
    
    local optimizations=""
    
    case "$platform" in
        "windows")
            optimizations="
# Windows Docker Desktop Optimizations
ONF_VOLUME_CONSISTENCY=delegated
ONF_VOLUME_CACHE_FROM_HOST=true
ONF_DOCKER_HOST_PATH_STYLE=windows
ONF_DOCKER_MEMORY_LIMIT=4G
ONF_DOCKER_CPU_LIMIT=4
ONF_DOCKER_SWAP_LIMIT=2G

# Windows Performance Tweaks
ONF_PHP_OPCACHE_MEMORY=256
ONF_PHP_REALPATH_CACHE_SIZE=1M
ONF_NGINX_SENDFILE=off
ONF_MARIADB_INNODB_FLUSH_LOG_AT_TRX_COMMIT=2
"
            ;;
        "macos")
            optimizations="
# macOS Docker Desktop Optimizations
ONF_VOLUME_CONSISTENCY=cached
ONF_VOLUME_NOCOPY=true
ONF_DOCKER_HOST_PATH_STYLE=posix
ONF_DOCKER_MEMORY_LIMIT=6G
ONF_DOCKER_CPU_LIMIT=0  # Use all available
ONF_DOCKER_SWAP_LIMIT=2G

# macOS Performance Tweaks
ONF_PHP_OPCACHE_MEMORY=512
ONF_PHP_REALPATH_CACHE_SIZE=2M
ONF_NGINX_SENDFILE=on
ONF_MARIADB_INNODB_FLUSH_LOG_AT_TRX_COMMIT=1
"
            ;;
        "linux"|"wsl")
            optimizations="
# Linux Native Optimizations
ONF_VOLUME_CONSISTENCY=consistent
ONF_VOLUME_DIRECT_MOUNT=true
ONF_DOCKER_HOST_PATH_STYLE=posix
ONF_DOCKER_MEMORY_LIMIT=0  # No limit
ONF_DOCKER_CPU_LIMIT=0     # Use all available
ONF_DOCKER_SWAP_LIMIT=0    # No limit

# Linux Performance Tweaks
ONF_PHP_OPCACHE_MEMORY=512
ONF_PHP_REALPATH_CACHE_SIZE=4M
ONF_NGINX_SENDFILE=on
ONF_NGINX_TCP_NOPUSH=on
ONF_NGINX_TCP_NODELAY=on
ONF_MARIADB_INNODB_FLUSH_LOG_AT_TRX_COMMIT=1
"
            ;;
    esac
    
    # Architecture-specific optimizations
    case "$arch" in
        "arm64")
            optimizations="$optimizations
# ARM64 Architecture Optimizations
ONF_DOCKER_PLATFORM=linux/arm64
ONF_PHP_OPCACHE_ENABLE_CLI=1
ONF_REDIS_MAXMEMORY_POLICY=allkeys-lfu
"
            ;;
        "x64")
            optimizations="$optimizations
# x64 Architecture Optimizations
ONF_DOCKER_PLATFORM=linux/amd64
ONF_PHP_JIT_BUFFER_SIZE=256M
ONF_REDIS_MAXMEMORY_POLICY=allkeys-lru
"
            ;;
    esac
    
    echo "$optimizations"
}

# Apply platform optimizations to .env file
apply_optimizations() {
    local env_file="$PROJECT_ROOT/.env"
    
    if [[ ! -f "$env_file" ]]; then
        echo -e "${RED}❌ .env file not found${NC}"
        return 1
    fi
    
    local platform_info=$(detect_platform)
    local optimizations=$(generate_optimizations)
    
    echo -e "${BLUE}🔧 Applying platform optimizations...${NC}"
    
    # Add platform detection info
    echo "" >> "$env_file"
    echo "# ========================================================================" >> "$env_file"
    echo "# 🚀 PLATFORM-SPECIFIC OPTIMIZATIONS (Auto-Generated)" >> "$env_file"
    echo "# ========================================================================" >> "$env_file"
    echo "" >> "$env_file"
    echo "# Platform Detection: $platform_info" >> "$env_file"
    echo "# Generated on: $(date)" >> "$env_file"
    echo "" >> "$env_file"
    
    # Add optimizations
    echo "$optimizations" >> "$env_file"
    
    echo -e "${GREEN}✅ Platform optimizations applied${NC}"
}

# Validate Docker configuration
validate_docker() {
    echo -e "${BLUE}🐳 Validating Docker configuration...${NC}"
    
    local platform_info=$(detect_platform)
    local platform=$(echo "$platform_info" | cut -d':' -f1)
    local docker_type=$(echo "$platform_info" | cut -d':' -f3)
    
    # Check Docker memory allocation
    local docker_memory=""
    if [[ "$docker_type" == "desktop" ]]; then
        case "$platform" in
            "windows")
                echo -e "${YELLOW}💡 Windows Docker Desktop detected${NC}"
                echo -e "${CYAN}   • Ensure at least 4GB RAM allocated to Docker${NC}"
                echo -e "${CYAN}   • Enable WSL 2 backend for better performance${NC}"
                echo -e "${CYAN}   • Disable 'Use the WSL 2 based engine' if experiencing issues${NC}"
                ;;
            "macos")
                echo -e "${YELLOW}💡 macOS Docker Desktop detected${NC}"
                echo -e "${CYAN}   • Ensure at least 6GB RAM allocated to Docker${NC}"
                echo -e "${CYAN}   • Enable VirtioFS for improved file sharing performance${NC}"
                echo -e "${CYAN}   • Consider using Colima for better performance${NC}"
                ;;
        esac
    fi
    
    # Check available memory
    local available_memory=""
    case "$platform" in
        "linux"|"wsl")
            available_memory=$(free -m | awk 'NR==2{printf "%.1f", $7/1024}')
            ;;
        "macos")
            available_memory=$(vm_stat | perl -ne '/free:\s+(\d+)/ and $free=$1; /speculative:\s+(\d+)/ and $spec=$1; END {printf "%.1f", ($free+$spec)*4096/1024/1024/1024}')
            ;;
    esac
    
    if [[ -n "$available_memory" ]]; then
        echo -e "${GREEN}✅ Available memory: ${available_memory}GB${NC}"
    fi
    
    # Check Docker volumes location
    local docker_root=$(docker info --format '{{.DockerRootDir}}' 2>/dev/null || echo "Unknown")
    echo -e "${GREEN}✅ Docker root: $docker_root${NC}"
    
    # Platform-specific recommendations
    case "$platform" in
        "windows")
            echo -e "${PURPLE}🎯 Windows Optimization Tips:${NC}"
            echo -e "${CYAN}   • Use Docker volumes instead of bind mounts${NC}"
            echo -e "${CYAN}   • Keep project files on C: drive for best performance${NC}"
            echo -e "${CYAN}   • Exclude Docker directories from Windows Defender${NC}"
            ;;
        "macos")
            echo -e "${PURPLE}🎯 macOS Optimization Tips:${NC}"
            echo -e "${CYAN}   • Use Docker volumes for best performance${NC}"
            echo -e "${CYAN}   • Avoid bind mounts when possible${NC}"
            echo -e "${CYAN}   • Consider using Colima instead of Docker Desktop${NC}"
            ;;
        "linux")
            echo -e "${PURPLE}🎯 Linux Optimization Tips:${NC}"
            echo -e "${CYAN}   • Hybrid mode works great on native Linux${NC}"
            echo -e "${CYAN}   • Bind mounts have excellent performance${NC}"
            echo -e "${CYAN}   • Consider using Podman for rootless containers${NC}"
            ;;
    esac
}

# Create platform-specific docker-compose override
create_platform_override() {
    local platform_info=$(detect_platform)
    local platform=$(echo "$platform_info" | cut -d':' -f1)
    local arch=$(echo "$platform_info" | cut -d':' -f2)
    
    local override_file="$PROJECT_ROOT/docker-compose.override.yml"
    
    echo -e "${BLUE}🔧 Creating platform-specific override...${NC}"
    
    cat > "$override_file" << EOF
# ONF-WP Platform-Specific Override
# Auto-generated for: $platform_info
# Generated on: $(date)

version: '3.8'

services:
  php:
    platform: linux/$arch
    environment:
      - ONF_PLATFORM_DETECTED=$platform
      - ONF_ARCH_DETECTED=$arch
    deploy:
      resources:
        limits:
          memory: \${ONF_DOCKER_MEMORY_LIMIT:-2G}
EOF

    case "$platform" in
        "windows")
            cat >> "$override_file" << EOF
        reservations:
          memory: 1G
    volumes:
      # Windows-optimized volume mounting
      - type: volume
        source: wp_core
        target: /var/www/html
        volume:
          nocopy: true
EOF
            ;;
        "macos")
            cat >> "$override_file" << EOF
        reservations:
          memory: 2G
    volumes:
      # macOS-optimized volume mounting with consistency
      - type: volume
        source: wp_core
        target: /var/www/html
        consistency: cached
EOF
            ;;
        "linux")
            cat >> "$override_file" << EOF
        reservations:
          memory: 512M
    volumes:
      # Linux native performance
      - type: volume
        source: wp_core
        target: /var/www/html
        consistency: consistent
EOF
            ;;
    esac

    cat >> "$override_file" << EOF

  nginx:
    platform: linux/$arch
    deploy:
      resources:
        limits:
          memory: 512M
        reservations:
          memory: 256M

  mariadb:
    platform: linux/$arch
    deploy:
      resources:
        limits:
          memory: 1G
        reservations:
          memory: 512M

  redis:
    platform: linux/$arch
    deploy:
      resources:
        limits:
          memory: 256M
        reservations:
          memory: 128M
EOF
    
    echo -e "${GREEN}✅ Platform override created: docker-compose.override.yml${NC}"
}

# Show platform analysis
show_platform_analysis() {
    local platform_info=$(detect_platform)
    local platform=$(echo "$platform_info" | cut -d':' -f1)
    local arch=$(echo "$platform_info" | cut -d':' -f2)
    local docker_type=$(echo "$platform_info" | cut -d':' -f3)
    
    local strategy_info=$(get_optimal_strategy)
    local strategy=$(echo "$strategy_info" | cut -d':' -f1)
    local reason=$(echo "$strategy_info" | cut -d':' -f2)
    
    echo -e "${CYAN}🔍 Platform Analysis Results:${NC}"
    echo ""
    echo -e "${WHITE}Operating System:${NC} ${GREEN}$platform${NC}"
    echo -e "${WHITE}Architecture:${NC} ${GREEN}$arch${NC}"
    echo -e "${WHITE}Docker Type:${NC} ${GREEN}$docker_type${NC}"
    echo ""
    echo -e "${WHITE}Recommended Strategy:${NC} ${GREEN}$strategy${NC}"
    echo -e "${WHITE}Reason:${NC} $reason"
    echo ""
}

# Main function
main() {
    case "${1:-analyze}" in
        "analyze")
            show_platform_analysis
            ;;
        "optimize")
            show_platform_analysis
            apply_optimizations
            create_platform_override
            validate_docker
            ;;
        "validate")
            validate_docker
            ;;
        "detect")
            detect_platform
            ;;
        "strategy")
            get_optimal_strategy | cut -d':' -f1
            ;;
        *)
            echo -e "${RED}❌ Unknown command: $1${NC}"
            echo -e "${YELLOW}Available commands: analyze, optimize, validate, detect, strategy${NC}"
            exit 1
            ;;
    esac
}

# Execute main function
main "$@" 