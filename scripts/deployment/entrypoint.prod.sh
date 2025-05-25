#!/bin/sh
# ONF-WP v1.0.5 Production Entrypoint Script
# Revolutionary WordPress hosting with enterprise-level automation

set -e  # Exit on any error
set -u  # Exit on undefined variables

# ============================================================================
# 🎯 Production Configuration & Logging
# ============================================================================

# Production paths and configuration
WP_ROOT="/var/www/html"
WP_CONFIG_PATH="${WP_ROOT}/wp-config.php"
WP_CONFIG_SAMPLE_PATH="/opt/onf-wp/wp-config-sample.php"
LOG_PREFIX="[ONF-WP v1.0.5 $(date '+%Y-%m-%d %H:%M:%S')]"

# Enhanced logging functions
log_info() {
    echo "${LOG_PREFIX} [INFO] $1" | tee -a /var/log/php/onf-wp.log
}

log_warn() {
    echo "${LOG_PREFIX} [WARN] $1" | tee -a /var/log/php/onf-wp.log >&2
}

log_error() {
    echo "${LOG_PREFIX} [ERROR] $1" | tee -a /var/log/php/onf-wp.log >&2
}

log_success() {
    echo "${LOG_PREFIX} [SUCCESS] $1" | tee -a /var/log/php/onf-wp.log
}

# ============================================================================
# 🔧 Environment Validation & Setup
# ============================================================================

log_info "Starting ONF-WP Production Environment Setup"

# Validate critical environment variables
validate_environment() {
    local required_vars="PROJECT_DOMAIN WORDPRESS_DB_HOST WORDPRESS_DB_NAME WORDPRESS_DB_USER WORDPRESS_DB_PASSWORD"
    local missing_vars=""
    
    for var in $required_vars; do
        if ! env | grep -q "^${var}="; then
            missing_vars="${missing_vars} ${var}"
        fi
    done
    
    if [ -n "$missing_vars" ]; then
        log_error "Missing required environment variables:$missing_vars"
        exit 1
    fi
    
    log_success "Environment validation passed"
}

# Test database connectivity with retry logic
test_database_connection() {
    local max_attempts=30
    local attempt=1
    
    log_info "Testing database connectivity..."
    
    while [ $attempt -le $max_attempts ]; do
        if mysql -h"$WORDPRESS_DB_HOST" -u"$WORDPRESS_DB_USER" -p"$WORDPRESS_DB_PASSWORD" "$WORDPRESS_DB_NAME" -e "SELECT 1;" >/dev/null 2>&1; then
            log_success "Database connection established"
            return 0
        fi
        
        log_warn "Database connection attempt $attempt/$max_attempts failed, retrying in 2s..."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    log_error "Failed to connect to database after $max_attempts attempts"
    exit 1
}

# Test Redis connectivity
test_redis_connection() {
    if [ -n "${REDIS_HOST:-}" ]; then
        log_info "Testing Redis connectivity..."
        
        if redis-cli -h "$REDIS_HOST" ping >/dev/null 2>&1; then
            log_success "Redis connection established"
            export REDIS_AVAILABLE=true
        else
            log_warn "Redis connection failed, continuing without cache"
            export REDIS_AVAILABLE=false
        fi
    else
        log_warn "Redis not configured"
        export REDIS_AVAILABLE=false
    fi
}

# ============================================================================
# 🚀 WordPress Installation & Configuration
# ============================================================================

# Download and install WordPress core if needed
install_wordpress_core() {
    if [ ! -f "${WP_ROOT}/wp-includes/version.php" ]; then
        log_info "WordPress core files not found, downloading..."
        
        # Ensure directory exists and has proper permissions
        mkdir -p "$WP_ROOT"
        cd "$WP_ROOT"
        
        # Download WordPress with increased timeout
        if wp core download \
            --path="$WP_ROOT" \
            --locale="en_US" \
            --version="latest" \
            --allow-root \
            --quiet; then
            log_success "WordPress core downloaded successfully"
        else
            log_error "Failed to download WordPress core"
            exit 1
        fi
    else
        log_info "WordPress core files already present"
    fi
}

# Generate production wp-config.php
generate_wp_config() {
    if [ ! -f "$WP_CONFIG_PATH" ] && [ -f "$WP_CONFIG_SAMPLE_PATH" ]; then
        log_info "Generating production wp-config.php..."
        
        # Copy sample config
        cp "$WP_CONFIG_SAMPLE_PATH" "$WP_CONFIG_PATH"
        
        # Fetch WordPress salts
        log_info "Fetching fresh WordPress security salts..."
        if SALTS=$(curl -fsSL --connect-timeout 10 --retry 3 https://api.wordpress.org/secret-key/1.1/salt/); then
            # Replace salt placeholders using a more robust method
            awk -v salts="$SALTS" '
                BEGIN { in_salt_block = 0 }
                /\/\*\*#@\+\// { 
                    in_salt_block = 1
                    print salts
                    next
                }
                /\/\*\*#@-\*\// { 
                    in_salt_block = 0
                    next
                }
                !in_salt_block { print }
            ' "$WP_CONFIG_PATH" > "${WP_CONFIG_PATH}.tmp" && mv "${WP_CONFIG_PATH}.tmp" "$WP_CONFIG_PATH"
            
            log_success "WordPress salts updated"
        else
            log_warn "Failed to fetch salts, using placeholders (less secure)"
        fi
        
        # Set proper file permissions
        chmod 644 "$WP_CONFIG_PATH"
        log_success "wp-config.php created with secure permissions"
        
    elif [ -f "$WP_CONFIG_PATH" ]; then
        log_info "wp-config.php already exists, skipping generation"
    else
        log_error "wp-config sample not found at $WP_CONFIG_SAMPLE_PATH"
        exit 1
    fi
}

# ============================================================================
# 🔌 Plugin Management & Optimization
# ============================================================================

# Install essential production plugins
install_production_plugins() {
    if [ -d "/opt/onf-wp/plugins" ]; then
        log_info "Installing production-optimized plugins..."
        
        # Copy plugins to WordPress
        for plugin_dir in /opt/onf-wp/plugins/*/; do
            if [ -d "$plugin_dir" ]; then
                plugin_name=$(basename "$plugin_dir")
                target_dir="${WP_ROOT}/wp-content/plugins/${plugin_name}"
                
                if [ ! -d "$target_dir" ]; then
                    log_info "Installing plugin: $plugin_name"
                    cp -r "$plugin_dir" "$target_dir"
                else
                    log_info "Plugin $plugin_name already installed"
                fi
            fi
        done
        
        log_success "Production plugins installed"
    fi
}

# Configure Redis Object Cache if available
configure_redis_cache() {
    if [ "$REDIS_AVAILABLE" = "true" ]; then
        log_info "Configuring Redis object cache..."
        
        # Create Redis cache configuration
        cat > "${WP_ROOT}/wp-content/object-cache.php" << 'EOF'
<?php
/**
 * ONF-WP Redis Object Cache Drop-in
 * Production-optimized Redis caching configuration
 */

// Redis configuration
$redis_config = [
    'host' => getenv('REDIS_HOST') ?: 'redis',
    'port' => (int)(getenv('REDIS_PORT') ?: 6379),
    'database' => (int)(getenv('REDIS_DATABASE') ?: 0),
    'timeout' => 1,
    'read_timeout' => 1,
    'retry_interval' => 100,
];

// Load Redis Object Cache plugin
if (file_exists(__DIR__ . '/plugins/redis-cache/includes/object-cache.php')) {
    require_once __DIR__ . '/plugins/redis-cache/includes/object-cache.php';
}
EOF
        
        log_success "Redis object cache configured"
    fi
}

# ============================================================================
# 🔒 Security Hardening
# ============================================================================

# Set secure file permissions
set_secure_permissions() {
    log_info "Setting secure file permissions..."
    
    # WordPress directory permissions
    find "$WP_ROOT" -type d -exec chmod 755 {} \;
    find "$WP_ROOT" -type f -exec chmod 644 {} \;
    
    # wp-config.php security
    if [ -f "$WP_CONFIG_PATH" ]; then
        chmod 600 "$WP_CONFIG_PATH"
    fi
    
    # .htaccess security
    if [ -f "${WP_ROOT}/.htaccess" ]; then
        chmod 644 "${WP_ROOT}/.htaccess"
    fi
    
    # Uploads directory
    if [ -d "${WP_ROOT}/wp-content/uploads" ]; then
        find "${WP_ROOT}/wp-content/uploads" -type d -exec chmod 755 {} \;
        find "${WP_ROOT}/wp-content/uploads" -type f -exec chmod 644 {} \;
    fi
    
    log_success "Secure file permissions set"
}

# Create security headers via .htaccess
create_security_headers() {
    if [ ! -f "${WP_ROOT}/.htaccess" ]; then
        log_info "Creating security-enhanced .htaccess..."
        
        cat > "${WP_ROOT}/.htaccess" << 'EOF'
# ONF-WP v1.0.5 Security & Performance Headers

# Security Headers
<IfModule mod_headers.c>
    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set X-Content-Type-Options "nosniff"
    Header always set X-XSS-Protection "1; mode=block"
    Header always set Referrer-Policy "strict-origin-when-cross-origin"
    Header always set Permissions-Policy "camera=(), microphone=(), geolocation=()"
</IfModule>

# WordPress security
<Files wp-config.php>
    order allow,deny
    deny from all
</Files>

<Files .htaccess>
    order allow,deny
    deny from all
</Files>

# Block access to sensitive files
<FilesMatch "\.(txt|log|md)$">
    order allow,deny
    deny from all
</FilesMatch>

# WordPress performance optimizations
<IfModule mod_expires.c>
    ExpiresActive On
    ExpiresByType text/css "access plus 1 year"
    ExpiresByType application/javascript "access plus 1 year"
    ExpiresByType image/png "access plus 1 year"
    ExpiresByType image/jpg "access plus 1 year"
    ExpiresByType image/jpeg "access plus 1 year"
    ExpiresByType image/gif "access plus 1 year"
    ExpiresByType image/webp "access plus 1 year"
</IfModule>

# Compression
<IfModule mod_deflate.c>
    AddOutputFilterByType DEFLATE text/plain
    AddOutputFilterByType DEFLATE text/html
    AddOutputFilterByType DEFLATE text/xml
    AddOutputFilterByType DEFLATE text/css
    AddOutputFilterByType DEFLATE application/xml
    AddOutputFilterByType DEFLATE application/xhtml+xml
    AddOutputFilterByType DEFLATE application/rss+xml
    AddOutputFilterByType DEFLATE application/javascript
    AddOutputFilterByType DEFLATE application/x-javascript
</IfModule>

# BEGIN WordPress
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]
RewriteBase /
RewriteRule ^index\.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]
</IfModule>
# END WordPress
EOF
        
        log_success "Security-enhanced .htaccess created"
    fi
}

# ============================================================================
# 🔄 Automated Maintenance & Optimization
# ============================================================================

# Optimize database on startup
optimize_database() {
    log_info "Running database optimization..."
    
    if wp db optimize --allow-root --path="$WP_ROOT" --quiet 2>/dev/null; then
        log_success "Database optimized"
    else
        log_warn "Database optimization skipped (WordPress not installed yet)"
    fi
}

# Clean up temporary files and optimize
cleanup_and_optimize() {
    log_info "Running cleanup and optimization..."
    
    # Clear any existing cache
    if [ -d "${WP_ROOT}/wp-content/cache" ]; then
        rm -rf "${WP_ROOT}/wp-content/cache"/*
        log_info "Cache directory cleaned"
    fi
    
    # Clean up temporary files
    find /tmp -type f -mtime +1 -delete 2>/dev/null || true
    find /var/log/php -name "*.log" -size +100M -exec truncate -s 50M {} \; 2>/dev/null || true
    
    # Flush Redis cache if available
    if [ "$REDIS_AVAILABLE" = "true" ]; then
        redis-cli -h "$REDIS_HOST" FLUSHDB >/dev/null 2>&1 || true
        log_info "Redis cache flushed"
    fi
    
    log_success "Cleanup and optimization completed"
}

# ============================================================================
# 🚀 Main Execution Flow
# ============================================================================

main() {
    log_info "=== ONF-WP v1.0.5 Production Startup ==="
    
    # Phase 1: Environment validation
    validate_environment
    test_database_connection
    test_redis_connection
    
    # Phase 2: WordPress setup
    install_wordpress_core
    generate_wp_config
    
    # Phase 3: Production optimization
    install_production_plugins
    configure_redis_cache
    
    # Phase 4: Security hardening
    set_secure_permissions
    create_security_headers
    
    # Phase 5: Maintenance and optimization
    optimize_database
    cleanup_and_optimize
    
    log_success "=== ONF-WP Production Environment Ready ==="
    log_info "WordPress site: ${SITE_PROTOCOL:-https}://${PROJECT_DOMAIN}"
    log_info "Admin area: ${SITE_PROTOCOL:-https}://${PROJECT_DOMAIN}/wp-admin/"
    log_info "Database management: ${SITE_PROTOCOL:-https}://db.${PROJECT_DOMAIN}"
    
    if [ "$REDIS_AVAILABLE" = "true" ]; then
        log_info "Redis object caching: ENABLED"
    else
        log_info "Redis object caching: DISABLED"
    fi
    
    # Execute the main command (PHP-FPM)
    log_info "Starting PHP-FPM process..."
    exec "$@"
}

# Handle signals gracefully
trap 'log_info "Received termination signal, shutting down gracefully..."; exit 0' TERM INT

# Start the main process
main "$@" 