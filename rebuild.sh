#!/usr/bin/env bash

# Nix Darwin Configuration Rebuild Script
# This script helps manage your Nix Darwin configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
FLAKE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Functions
print_help() {
    echo "Nix Darwin Configuration Manager"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  build     Build the configuration without applying"
    echo "  switch    Build and apply the configuration"
    echo "  update    Update flake inputs and rebuild"
    echo "  check     Check configuration for errors"
    echo "  show      Show available configuration outputs"
    echo "  clean     Clean up old generations"
    echo "  rollback  Rollback to previous generation"
    echo "  help      Show this help message"
    echo ""
    echo "Options:"
    echo "  --dry-run    Show what would be done without doing it"
    echo "  --verbose    Show verbose output"
    echo ""
    echo "Examples:"
    echo "  $0 switch                 # Apply configuration"
    echo "  $0 update                 # Update and rebuild"
    echo "  $0 build --dry-run        # Test build without applying"
}

log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Check if we're in the right directory
check_directory() {
    if [[ ! -f "$FLAKE_DIR/flake.nix" ]]; then
        error "flake.nix not found at $FLAKE_DIR/flake.nix"
    fi
}

# Get hostname from flake.nix
get_hostname() {
    if [[ -f "$FLAKE_DIR/flake.nix" ]]; then
        grep -o 'hostName = "[^"]*"' "$FLAKE_DIR/flake.nix" | sed 's/hostName = "\(.*\)"/\1/' || echo "Mikes-MacBook-Pro"
    else
        echo "Mikes-MacBook-Pro"
    fi
}

# Build configuration
build_config() {
    local hostname=$(get_hostname)
    local dry_run=$1
    
    log "Building configuration for host: $hostname"
    
    cd "$FLAKE_DIR" || error "Failed to change to $FLAKE_DIR"
    
    if [[ "$dry_run" == "true" ]]; then
        log "Dry run mode - showing what would be built"
        nix build ".#darwinConfigurations.$hostname.system" --dry-run
    else
        nix build ".#darwinConfigurations.$hostname.system"
    fi
}

# Switch configuration
switch_config() {
    local dry_run=$1
    local verbose=$2
    
    log "Switching to new configuration..."
    
    cd "$FLAKE_DIR" || error "Failed to change to $FLAKE_DIR"
    
    local cmd="sudo darwin-rebuild switch --flake $FLAKE_DIR/.#"
    
    if [[ "$verbose" == "true" ]]; then
        cmd="$cmd --verbose"
    fi
    
    if [[ "$dry_run" == "true" ]]; then
        log "Would run: $cmd"
    else
        eval "$cmd"
        success "Configuration applied successfully!"
        warn "Some changes may require a logout/login to take effect"
    fi
}

# Update flake inputs
update_flake() {
    log "Updating flake inputs..."
    
    cd "$FLAKE_DIR" || error "Failed to change to $FLAKE_DIR"
    
    nix flake update
    success "Flake inputs updated"
}

# Check configuration
check_config() {
    log "Checking configuration..."
    
    cd "$FLAKE_DIR" || error "Failed to change to $FLAKE_DIR"
    
    nix flake check
    success "Configuration check passed"
}

# Show configuration outputs
show_config() {
    log "Available configuration outputs:"
    
    cd "$FLAKE_DIR" || error "Failed to change to $FLAKE_DIR"
    
    nix flake show
}

# Clean old generations
clean_generations() {
    log "Cleaning old generations..."
    
    # Clean nix-darwin generations (keep last 5)
    sudo nix-collect-garbage --delete-older-than 30d
    
    # Clean home-manager generations
    home-manager expire-generations "-30 days" 2>/dev/null || true
    
    success "Old generations cleaned"
}

# Rollback to previous generation
rollback_config() {
    warn "Rolling back to previous generation..."
    
    sudo darwin-rebuild rollback
    
    success "Rolled back to previous generation"
}

# Parse command line arguments
DRY_RUN=false
VERBOSE=false
COMMAND=""

while [[ $# -gt 0 ]]; do
    case $1 in
        build|switch|update|check|show|clean|rollback|help)
            COMMAND="$1"
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        *)
            error "Unknown option or command: $1"
            ;;
    esac
done

# Default to help if no command provided
if [[ -z "$COMMAND" ]]; then
    COMMAND="help"
fi

# Execute command
case $COMMAND in
    build)
        check_directory
        build_config "$DRY_RUN"
        ;;
    switch)
        check_directory
        build_config "$DRY_RUN"
        if [[ "$DRY_RUN" != "true" ]]; then
            switch_config "$DRY_RUN" "$VERBOSE"
        fi
        ;;
    update)
        check_directory
        update_flake
        build_config "$DRY_RUN"
        if [[ "$DRY_RUN" != "true" ]]; then
            switch_config "$DRY_RUN" "$VERBOSE"
        fi
        ;;
    check)
        check_directory
        check_config
        ;;
    show)
        check_directory
        show_config
        ;;
    clean)
        clean_generations
        ;;
    rollback)
        rollback_config
        ;;
    help)
        print_help
        ;;
    *)
        error "Unknown command: $COMMAND"
        ;;
esac