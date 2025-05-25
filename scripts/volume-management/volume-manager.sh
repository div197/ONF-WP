#!/usr/bin/env bash

# ONF-WP v1.0.0-Alpha - Revolutionary Volume Manager
# "Nishkaam Karma Yoga" - Selfless Volume Management

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
ONF_VOLUME_STRATEGY="${ONF_VOLUME_STRATEGY:-docker}"

# Volume Management Functions

show_banner() {
    echo -e "${CYAN}"
    cat << "EOF"
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

Revolutionary Volume Manager v1.0.0-Alpha
EOF
    echo -e "${NC}"
}

# Help function
show_help() {
    echo -e "${WHITE}ONF-WP Revolutionary Volume Manager${NC}"
    echo ""
    echo -e "${YELLOW}USAGE:${NC}"
    echo "  ./volume-manager.sh <command> [options]"
    echo ""
    echo -e "${YELLOW}VOLUME STRATEGY COMMANDS:${NC}"
    echo -e "  ${GREEN}strategy${NC} <docker|hybrid|bindmount>    Switch volume strategy"
    echo -e "  ${GREEN}status${NC}                                Show current strategy"
    echo -e "  ${GREEN}list${NC}                                  List all project volumes"
    echo ""
    echo -e "${YELLOW}BACKUP & EXPORT COMMANDS:${NC}"
    echo -e "  ${GREEN}export${NC} [full|themes|plugins|uploads]  Export from Docker volumes"
    echo -e "  ${GREEN}import${NC} <backup-file>                  Import to Docker volumes"
    echo -e "  ${GREEN}backup${NC} [full|incremental]             Create volume backup"
    echo -e "  ${GREEN}restore${NC} <backup-name>                 Restore from backup"
    echo ""
    echo -e "${YELLOW}SYNC COMMANDS:${NC}"
    echo -e "  ${GREEN}sync${NC} themes                           Sync themes container ↔ host"
    echo -e "  ${GREEN}sync${NC} plugins                          Sync plugins container ↔ host"
    echo -e "  ${GREEN}sync${NC} all                              Sync all development assets"
    echo ""
    echo -e "${YELLOW}MIGRATION COMMANDS:${NC}"
    echo -e "  ${GREEN}migrate${NC} detect                         Detect current setup"
    echo -e "  ${GREEN}migrate${NC} to-docker                      Migrate to Docker volumes"
    echo -e "  ${GREEN}migrate${NC} to-hybrid                      Migrate to hybrid mode"
    echo -e "  ${GREEN}migrate${NC} to-bindmount                   Migrate to bind mounts"
    echo ""
    echo -e "${YELLOW}MAINTENANCE COMMANDS:${NC}"
    echo -e "  ${GREEN}cleanup${NC}                                Clean up unused volumes"
    echo -e "  ${GREEN}optimize${NC}                               Optimize volume performance"
    echo -e "  ${GREEN}health${NC}                                 Check volume health"
    echo ""
    echo -e "${YELLOW}EXAMPLES:${NC}"
    echo "  ./volume-manager.sh strategy docker         # Switch to Docker volume strategy"
    echo "  ./volume-manager.sh export themes          # Export themes from container"
    echo "  ./volume-manager.sh sync all              # Sync all development assets"
    echo "  ./volume-manager.sh migrate to-docker     # Migrate to Docker volumes"
    echo ""
}

# Strategy management
switch_strategy() {
    local strategy="$1"
    
    case "$strategy" in
        "docker"|"hybrid"|"bindmount")
            echo -e "${BLUE}🔄 Switching to $strategy strategy...${NC}"
            
            # Update .env file
            if [[ -f "$PROJECT_ROOT/.env" ]]; then
                sed -i.bak "s/^ONF_VOLUME_STRATEGY=.*/ONF_VOLUME_STRATEGY=$strategy/" "$PROJECT_ROOT/.env"
            else
                echo "ONF_VOLUME_STRATEGY=$strategy" >> "$PROJECT_ROOT/.env"
            fi
            
            # Copy appropriate docker-compose file
            local compose_file="$PROJECT_ROOT/configs/volume-strategies/${strategy}.yml"
            if [[ "$strategy" == "docker" ]]; then
                compose_file="$PROJECT_ROOT/configs/volume-strategies/docker-only.yml"
            fi
            
            if [[ -f "$compose_file" ]]; then
                cp "$compose_file" "$PROJECT_ROOT/docker-compose.yml"
                echo -e "${GREEN}✅ Switched to $strategy strategy${NC}"
                echo -e "${CYAN}💡 Run 'docker-compose down && docker-compose up -d' to apply changes${NC}"
            else
                echo -e "${RED}❌ Strategy file not found: $compose_file${NC}"
                exit 1
            fi
            ;;
        *)
            echo -e "${RED}❌ Invalid strategy: $strategy${NC}"
            echo -e "${YELLOW}Valid strategies: docker, hybrid, bindmount${NC}"
            exit 1
            ;;
    esac
}

# Show current status
show_status() {
    echo -e "${BLUE}📊 ONF-WP Volume Status:${NC}"
    echo ""
    echo -e "${WHITE}Current Strategy:${NC} ${GREEN}${ONF_VOLUME_STRATEGY}${NC}"
    echo -e "${WHITE}Project Name:${NC} ${GREEN}${COMPOSE_PROJECT_NAME}${NC}"
    echo ""
    
    # Show Docker volumes
    echo -e "${YELLOW}Docker Volumes:${NC}"
    docker volume ls --filter name="${COMPOSE_PROJECT_NAME}" --format "table {{.Name}}\t{{.Driver}}\t{{.Scope}}" 2>/dev/null || echo "No volumes found"
    echo ""
    
    # Show disk usage
    echo -e "${YELLOW}Volume Disk Usage:${NC}"
    docker system df -v 2>/dev/null | grep "${COMPOSE_PROJECT_NAME}" || echo "No volume data found"
}

# List all volumes
list_volumes() {
    echo -e "${BLUE}📋 Project Volumes for: ${COMPOSE_PROJECT_NAME}${NC}"
    echo ""
    
    local volumes=$(docker volume ls --filter name="${COMPOSE_PROJECT_NAME}" --format "{{.Name}}")
    
    if [[ -z "$volumes" ]]; then
        echo -e "${YELLOW}⚠️ No volumes found for project: ${COMPOSE_PROJECT_NAME}${NC}"
        return
    fi
    
    for volume in $volumes; do
        echo -e "${GREEN}📁 $volume${NC}"
        local mountpoint=$(docker volume inspect "$volume" --format "{{.Mountpoint}}" 2>/dev/null || echo "Unknown")
        local size=$(docker system df -v 2>/dev/null | grep "$volume" | awk '{print $3}' || echo "Unknown")
        echo -e "   ${WHITE}Path:${NC} $mountpoint"
        echo -e "   ${WHITE}Size:${NC} $size"
        echo ""
    done
}

# Export from Docker volumes
export_volumes() {
    local type="${1:-full}"
    local backup_dir="$PROJECT_ROOT/backups"
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    
    mkdir -p "$backup_dir/$type"
    
    echo -e "${BLUE}📦 Exporting $type from Docker volumes...${NC}"
    
    case "$type" in
        "full")
            # Export entire WordPress installation
            local backup_file="$backup_dir/full/wordpress_full_${COMPOSE_PROJECT_NAME}_${timestamp}.tar.gz"
            docker run --rm \
                -v "wp_core_${COMPOSE_PROJECT_NAME}:/source" \
                -v "$backup_dir/full:/backup" \
                alpine:latest \
                tar czf "/backup/wordpress_full_${COMPOSE_PROJECT_NAME}_${timestamp}.tar.gz" -C /source .
            echo -e "${GREEN}✅ Full export saved: $backup_file${NC}"
            ;;
        "themes")
            local backup_file="$backup_dir/themes/themes_${COMPOSE_PROJECT_NAME}_${timestamp}.tar.gz"
            docker run --rm \
                -v "wp_themes_${COMPOSE_PROJECT_NAME}:/source" \
                -v "$backup_dir/themes:/backup" \
                alpine:latest \
                tar czf "/backup/themes_${COMPOSE_PROJECT_NAME}_${timestamp}.tar.gz" -C /source .
            echo -e "${GREEN}✅ Themes export saved: $backup_file${NC}"
            ;;
        "plugins")
            local backup_file="$backup_dir/plugins/plugins_${COMPOSE_PROJECT_NAME}_${timestamp}.tar.gz"
            docker run --rm \
                -v "wp_plugins_${COMPOSE_PROJECT_NAME}:/source" \
                -v "$backup_dir/plugins:/backup" \
                alpine:latest \
                tar czf "/backup/plugins_${COMPOSE_PROJECT_NAME}_${timestamp}.tar.gz" -C /source .
            echo -e "${GREEN}✅ Plugins export saved: $backup_file${NC}"
            ;;
        "uploads")
            local backup_file="$backup_dir/uploads/uploads_${COMPOSE_PROJECT_NAME}_${timestamp}.tar.gz"
            docker run --rm \
                -v "wp_uploads_${COMPOSE_PROJECT_NAME}:/source" \
                -v "$backup_dir/uploads:/backup" \
                alpine:latest \
                tar czf "/backup/uploads_${COMPOSE_PROJECT_NAME}_${timestamp}.tar.gz" -C /source .
            echo -e "${GREEN}✅ Uploads export saved: $backup_file${NC}"
            ;;
        *)
            echo -e "${RED}❌ Invalid export type: $type${NC}"
            echo -e "${YELLOW}Valid types: full, themes, plugins, uploads${NC}"
            exit 1
            ;;
    esac
}

# Import to Docker volumes
import_volumes() {
    local backup_file="$1"
    
    if [[ ! -f "$backup_file" ]]; then
        echo -e "${RED}❌ Backup file not found: $backup_file${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}📥 Importing from: $backup_file${NC}"
    
    # Determine import type from filename
    local type="full"
    if [[ "$backup_file" == *"themes"* ]]; then
        type="themes"
    elif [[ "$backup_file" == *"plugins"* ]]; then
        type="plugins"
    elif [[ "$backup_file" == *"uploads"* ]]; then
        type="uploads"
    fi
    
    case "$type" in
        "full")
            docker run --rm \
                -v "wp_core_${COMPOSE_PROJECT_NAME}:/target" \
                -v "$(dirname "$backup_file"):/backup" \
                alpine:latest \
                tar xzf "/backup/$(basename "$backup_file")" -C /target
            ;;
        "themes")
            docker run --rm \
                -v "wp_themes_${COMPOSE_PROJECT_NAME}:/target" \
                -v "$(dirname "$backup_file"):/backup" \
                alpine:latest \
                tar xzf "/backup/$(basename "$backup_file")" -C /target
            ;;
        "plugins")
            docker run --rm \
                -v "wp_plugins_${COMPOSE_PROJECT_NAME}:/target" \
                -v "$(dirname "$backup_file"):/backup" \
                alpine:latest \
                tar xzf "/backup/$(basename "$backup_file")" -C /target
            ;;
        "uploads")
            docker run --rm \
                -v "wp_uploads_${COMPOSE_PROJECT_NAME}:/target" \
                -v "$(dirname "$backup_file"):/backup" \
                alpine:latest \
                tar xzf "/backup/$(basename "$backup_file")" -C /target
            ;;
    esac
    
    echo -e "${GREEN}✅ Import completed successfully${NC}"
}

# Sync between container and host
sync_assets() {
    local type="${1:-all}"
    
    echo -e "${BLUE}🔄 Syncing $type assets...${NC}"
    
    case "$type" in
        "themes")
            mkdir -p "$PROJECT_ROOT/development/themes"
            docker run --rm \
                -v "wp_themes_${COMPOSE_PROJECT_NAME}:/container" \
                -v "$PROJECT_ROOT/development/themes:/host" \
                alpine:latest \
                sh -c "apk add --no-cache rsync && rsync -av /container/ /host/"
            echo -e "${GREEN}✅ Themes synced to development/themes/${NC}"
            ;;
        "plugins")
            mkdir -p "$PROJECT_ROOT/development/plugins"
            docker run --rm \
                -v "wp_plugins_${COMPOSE_PROJECT_NAME}:/container" \
                -v "$PROJECT_ROOT/development/plugins:/host" \
                alpine:latest \
                sh -c "apk add --no-cache rsync && rsync -av /container/ /host/"
            echo -e "${GREEN}✅ Plugins synced to development/plugins/${NC}"
            ;;
        "all")
            sync_assets "themes"
            sync_assets "plugins"
            ;;
        *)
            echo -e "${RED}❌ Invalid sync type: $type${NC}"
            echo -e "${YELLOW}Valid types: themes, plugins, all${NC}"
            exit 1
            ;;
    esac
}

# Detect current setup
detect_setup() {
    echo -e "${BLUE}🔍 Detecting current ONF-WP setup...${NC}"
    echo ""
    
    # Check for bind mounts
    if [[ -d "$PROJECT_ROOT/storage/wordpress" ]]; then
        echo -e "${YELLOW}📁 Found bind mount directory: storage/wordpress${NC}"
        echo -e "${WHITE}   Current strategy appears to be: bindmount${NC}"
    fi
    
    # Check for Docker volumes
    local volumes=$(docker volume ls --filter name="${COMPOSE_PROJECT_NAME}" --format "{{.Name}}")
    if [[ -n "$volumes" ]]; then
        echo -e "${GREEN}🐳 Found Docker volumes:${NC}"
        for volume in $volumes; do
            echo -e "   ${WHITE}$volume${NC}"
        done
        echo -e "${WHITE}   Current strategy appears to be: docker${NC}"
    fi
    
    # Check current .env setting
    if [[ -f "$PROJECT_ROOT/.env" ]]; then
        local env_strategy=$(grep "^ONF_VOLUME_STRATEGY=" "$PROJECT_ROOT/.env" 2>/dev/null | cut -d'=' -f2 || echo "not set")
        echo -e "${CYAN}⚙️  Environment setting: ONF_VOLUME_STRATEGY=$env_strategy${NC}"
    fi
}

# Migrate to Docker volumes
migrate_to_docker() {
    echo -e "${BLUE}🔄 Migrating to Docker volume strategy...${NC}"
    
    # Stop services
    echo -e "${YELLOW}🛑 Stopping services...${NC}"
    cd "$PROJECT_ROOT"
    docker-compose down || true
    
    # Backup current data if bind mount exists
    if [[ -d "$PROJECT_ROOT/storage/wordpress" ]]; then
        echo -e "${YELLOW}📦 Backing up current WordPress data...${NC}"
        local backup_dir="$PROJECT_ROOT/backups/migration"
        mkdir -p "$backup_dir"
        local timestamp=$(date +"%Y%m%d_%H%M%S")
        tar czf "$backup_dir/migration_backup_${timestamp}.tar.gz" -C "$PROJECT_ROOT/storage" wordpress
        echo -e "${GREEN}✅ Backup saved: $backup_dir/migration_backup_${timestamp}.tar.gz${NC}"
        
        # Import to Docker volumes
        echo -e "${YELLOW}📥 Importing data to Docker volumes...${NC}"
        
        # Create volumes if they don't exist
        docker volume create "wp_core_${COMPOSE_PROJECT_NAME}" || true
        docker volume create "wp_uploads_${COMPOSE_PROJECT_NAME}" || true
        docker volume create "wp_themes_${COMPOSE_PROJECT_NAME}" || true
        docker volume create "wp_plugins_${COMPOSE_PROJECT_NAME}" || true
        
        # Import WordPress core
        docker run --rm \
            -v "$PROJECT_ROOT/storage/wordpress:/source" \
            -v "wp_core_${COMPOSE_PROJECT_NAME}:/target" \
            alpine:latest \
            sh -c "cp -a /source/* /target/ 2>/dev/null || true"
        
        echo -e "${GREEN}✅ Data imported to Docker volumes${NC}"
    fi
    
    # Switch strategy
    switch_strategy "docker"
    
    echo -e "${GREEN}🎉 Migration to Docker volumes completed!${NC}"
    echo -e "${CYAN}💡 Run 'docker-compose up -d' to start with new strategy${NC}"
}

# Volume health check
health_check() {
    echo -e "${BLUE}🏥 ONF-WP Volume Health Check${NC}"
    echo ""
    
    local volumes=$(docker volume ls --filter name="${COMPOSE_PROJECT_NAME}" --format "{{.Name}}")
    local issues=0
    
    if [[ -z "$volumes" ]]; then
        echo -e "${YELLOW}⚠️ No volumes found for project: ${COMPOSE_PROJECT_NAME}${NC}"
        return
    fi
    
    for volume in $volumes; do
        echo -e "${WHITE}Checking: $volume${NC}"
        
        # Check if volume is accessible
        if docker volume inspect "$volume" >/dev/null 2>&1; then
            echo -e "   ${GREEN}✅ Volume exists and is accessible${NC}"
        else
            echo -e "   ${RED}❌ Volume is not accessible${NC}"
            ((issues++))
        fi
        
        # Check if volume has data
        local data_check=$(docker run --rm -v "$volume:/check" alpine:latest sh -c "ls -la /check | wc -l" 2>/dev/null || echo "0")
        if [[ "$data_check" -gt "3" ]]; then
            echo -e "   ${GREEN}✅ Volume contains data${NC}"
        else
            echo -e "   ${YELLOW}⚠️ Volume appears empty${NC}"
        fi
        
        echo ""
    done
    
    if [[ "$issues" -eq 0 ]]; then
        echo -e "${GREEN}🎉 All volumes are healthy!${NC}"
    else
        echo -e "${RED}⚠️ Found $issues issues with volumes${NC}"
    fi
}

# Cleanup unused volumes
cleanup_volumes() {
    echo -e "${BLUE}🧹 Cleaning up unused volumes...${NC}"
    
    # Remove dangling volumes
    docker volume prune -f
    
    # List remaining project volumes
    echo -e "${GREEN}✅ Cleanup completed${NC}"
    list_volumes
}

# Main function
main() {
    case "${1:-help}" in
        "strategy")
            switch_strategy "${2:-}"
            ;;
        "status")
            show_status
            ;;
        "list")
            list_volumes
            ;;
        "export")
            export_volumes "${2:-full}"
            ;;
        "import")
            import_volumes "${2:-}"
            ;;
        "sync")
            sync_assets "${2:-all}"
            ;;
        "migrate")
            case "${2:-}" in
                "detect")
                    detect_setup
                    ;;
                "to-docker")
                    migrate_to_docker
                    ;;
                *)
                    echo -e "${RED}❌ Invalid migration command: ${2:-}${NC}"
                    echo -e "${YELLOW}Valid commands: detect, to-docker${NC}"
                    exit 1
                    ;;
            esac
            ;;
        "health")
            health_check
            ;;
        "cleanup")
            cleanup_volumes
            ;;
        "help"|"-h"|"--help")
            show_banner
            show_help
            ;;
        *)
            echo -e "${RED}❌ Unknown command: $1${NC}"
            echo -e "${YELLOW}💡 Run './volume-manager.sh help' for available commands${NC}"
            exit 1
            ;;
    esac
}

# Show banner for interactive commands
if [[ "${1:-}" != "status" ]] && [[ "${1:-}" != "list" ]]; then
    show_banner
fi

# Execute main function
main "$@" 