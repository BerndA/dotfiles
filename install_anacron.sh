#!/bin/bash
set -euo pipefail

# Anacron Installation and Setup Script
# Sets up anacron for scheduled tasks in ~/.anacron
# Supports systemd timers and cron-based scheduling

# Configuration
ANACRON_HOME="${ANACRON_HOME:-$HOME/.anacron}"
ANACRON_LOG_FILE="${ANACRON_LOG_FILE:-$HOME/.anacron.install.log}"
DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
DOTFILES_SYSTEMD_USER="${DOTFILES_SYSTEMD_USER:-$HOME/.config/systemd/user}"

# Flags
MODE="${ANACRON_MODE:-systemd}"  # systemd or cron
INTERACTIVE="${INTERACTIVE:-true}"
VERBOSE="${VERBOSE:-false}"

# Exit codes
EXIT_SUCCESS=0
EXIT_FATAL=1
EXIT_WARNINGS=2

# ============================================================================
# Logging and output functions
# ============================================================================

log() {
    local message="$1"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $message" | tee -a "$ANACRON_LOG_FILE"
}

log_info() {
    echo "ℹ  $1"
    echo "ℹ  $1" >> "$ANACRON_LOG_FILE"
}

log_success() {
    echo "✓ $1"
    echo "✓ $1" >> "$ANACRON_LOG_FILE"
}

log_warn() {
    echo "⚠ $1"
    echo "⚠ $1" >> "$ANACRON_LOG_FILE"
}

log_error() {
    echo "✗ $1"
    echo "✗ $1" >> "$ANACRON_LOG_FILE"
}

verbose_log() {
    if [[ "$VERBOSE" == "true" ]]; then
        log_info "$1"
    fi
}

# ============================================================================
# Validation
# ============================================================================

validate_requirements() {
    log_info "Validating requirements..."

    # Check if anacron is installed
    if ! command -v anacron &> /dev/null; then
        log_error "anacron not installed. Run: sudo apt-get install anacron"
        return 1
    fi

    # Check writable directories
    if [[ ! -w "$HOME" ]]; then
        log_error "Home directory $HOME is not writable"
        return 1
    fi

    log_success "All requirements validated"
    return 0
}

# ============================================================================
# Anacron Directory and Config Setup
# ============================================================================

setup_anacron_directories() {
    log_info "Setting up anacron directories..."

    # Create anacron directory structure
    mkdir -p "$ANACRON_HOME"/{spool,cron.daily,cron.weekly,cron.monthly}
    log_success "Created anacron directories"

    # Create anacrontab configuration
    if [[ ! -f "$ANACRON_HOME/anacrontab" ]]; then
        log_info "Creating anacrontab configuration..."
        cat > "$ANACRON_HOME/anacrontab" << 'ANACRONTAB_EOF'
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# These replace cron's entries
1 5 daily-cron nice run-parts --report ${HOME}/.anacron/cron.daily
7 10 weekly-cron nice run-parts --report ${HOME}/.anacron/cron.weekly
@monthly 15 monthly-cron nice run-parts --report ${HOME}/.anacron/cron.monthly
ANACRONTAB_EOF
        log_success "Created anacrontab"
    else
        verbose_log "anacrontab already exists"
    fi
}

# ============================================================================
# Systemd Setup (Preferred Method)
# ============================================================================

setup_systemd_anacron() {
    log_info "Setting up anacron via systemd user services..."

    # Create systemd user directory
    mkdir -p "$DOTFILES_SYSTEMD_USER"

    # Check if anacron service files exist in dotfiles
    if [[ ! -f "$DOTFILES_DIR/.config/systemd/user/anacron.service" ]] || [[ ! -f "$DOTFILES_DIR/.config/systemd/user/anacron.timer" ]]; then
        log_warn "anacron.service or anacron.timer not found in dotfiles"
        log_info "Creating default anacron service files..."

        # Create anacron.service
        cat > "$DOTFILES_SYSTEMD_USER/anacron.service" << 'SYSTEMD_SERVICE_EOF'
[Unit]
Description=Anacron job executor
Documentation=man:anacron(8)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/sbin/anacron -s -t %h/.anacron/anacrontab -S %h/.anacron/spool
Restart=always
RestartSec=300
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=default.target
SYSTEMD_SERVICE_EOF
        log_success "Created anacron.service"

        # Create anacron.timer
        cat > "$DOTFILES_SYSTEMD_USER/anacron.timer" << 'SYSTEMD_TIMER_EOF'
[Unit]
Description=Anacron job executor timer
Documentation=man:anacron(8)

[Timer]
OnBootSec=5min
OnUnitActiveSec=1h
Persistent=true

[Install]
WantedBy=timers.target
SYSTEMD_TIMER_EOF
        log_success "Created anacron.timer"
    else
        # Link existing service files from dotfiles
        if [[ ! -f "$DOTFILES_SYSTEMD_USER/anacron.service" ]]; then
            ln -s "$DOTFILES_DIR/.config/systemd/user/anacron.service" "$DOTFILES_SYSTEMD_USER/anacron.service"
            log_success "Linked anacron.service"
        fi

        if [[ ! -f "$DOTFILES_SYSTEMD_USER/anacron.timer" ]]; then
            ln -s "$DOTFILES_DIR/.config/systemd/user/anacron.timer" "$DOTFILES_SYSTEMD_USER/anacron.timer"
            log_success "Linked anacron.timer"
        fi
    fi

    # Enable and start the timer
    log_info "Enabling anacron timer..."
    systemctl --user daemon-reload
    systemctl --user enable anacron.timer
    systemctl --user start anacron.timer

    log_success "Anacron timer enabled and started"
}

# ============================================================================
# Cron Setup (Fallback Method)
# ============================================================================

setup_cron_anacron() {
    log_info "Setting up anacron via cron..."

    # Check if cron is available
    if ! command -v crontab &> /dev/null; then
        log_error "crontab not found. Install cron or use systemd mode instead."
        return 1
    fi

    # Add anacron to crontab
    local cron_entry="@hourly /usr/sbin/anacron -s -t \$HOME/.anacron/anacrontab -S \$HOME/.anacron/spool"

    # Get current crontab (if exists)
    local current_crontab=""
    if crontab -l 2>/dev/null; then
        current_crontab=$(crontab -l 2>/dev/null)
    fi

    # Check if anacron entry already exists
    if echo "$current_crontab" | grep -q "anacron"; then
        log_warn "Anacron entry already exists in crontab"
        return 0
    fi

    # Add anacron entry to crontab
    if [[ -n "$current_crontab" ]]; then
        echo "$current_crontab" | (crontab -; echo "$cron_entry") | crontab -
    else
        echo "$cron_entry" | crontab -
    fi

    log_success "Anacron added to crontab"
}

# ============================================================================
# Mode Selection
# ============================================================================

select_mode() {
    if [[ "$INTERACTIVE" != "true" ]]; then
        verbose_log "Non-interactive mode: using $MODE"
        return 0
    fi

    log_info "Select anacron scheduling mode:"
    echo "  1) systemd (preferred, uses user timers)"
    echo "  2) cron (fallback, uses crontab)"

    read -rp "Choose mode [1-2] (default: 1): " -n 1 choice
    echo

    case "$choice" in
        2)
            MODE="cron"
            ;;
        1|"")
            MODE="systemd"
            ;;
        *)
            log_warn "Invalid choice, using systemd"
            MODE="systemd"
            ;;
    esac

    log_info "Using mode: $MODE"
}

# ============================================================================
# Cleanup and Summary
# ============================================================================

print_summary() {
    local exit_code="$1"

    echo ""
    echo "============================================"
    echo "Anacron Installation Summary"
    echo "============================================"
    echo "Anacron Home: $ANACRON_HOME"
    echo "Scheduling Mode: $MODE"
    echo "Log file: $ANACRON_LOG_FILE"
    echo "============================================"

    case "$exit_code" in
        "$EXIT_SUCCESS")
            echo "✓ Anacron installation completed successfully"
            ;;
        "$EXIT_WARNINGS")
            echo "⚠ Anacron installation completed with warnings"
            ;;
        "$EXIT_FATAL")
            echo "✗ Anacron installation failed"
            ;;
    esac
    echo "============================================"
}

trap_exit() {
    local exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        log_error "Anacron installation failed with exit code $exit_code"
    fi

    print_summary "$exit_code"
    return "$exit_code"
}

# ============================================================================
# Parse Command Line Arguments
# ============================================================================

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --systemd)
                MODE="systemd"
                INTERACTIVE="false"
                ;;
            --cron)
                MODE="cron"
                INTERACTIVE="false"
                ;;
            --interactive)
                INTERACTIVE="true"
                ;;
            --verbose)
                VERBOSE="true"
                ;;
            --help)
                show_help
                exit "$EXIT_SUCCESS"
                ;;
            *)
                log_warn "Unknown option: $1"
                ;;
        esac
        shift
    done
}

show_help() {
    cat << 'HELP_EOF'
Anacron Installation and Setup Script

Usage: ./install_anacron.sh [OPTIONS]

Options:
  --systemd       Use systemd user timer (default)
  --cron          Use cron scheduling (fallback)
  --interactive   Enable interactive mode to select scheduler
  --verbose       Enable verbose logging
  --help          Show this help message

Examples:
  ./install_anacron.sh              # Interactive mode (will prompt)
  ./install_anacron.sh --systemd    # Use systemd directly
  ./install_anacron.sh --cron       # Use cron scheduling
  ./install_anacron.sh --verbose    # Show detailed output

Note:
  - Requires anacron to be installed: sudo apt-get install anacron
  - Systemd mode requires systemd user environment
  - Cron mode requires crontab utility

HELP_EOF
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
    # Initialize
    mkdir -p "$(dirname "$ANACRON_LOG_FILE")"
    trap trap_exit EXIT

    log "Starting anacron installation..."

    # Parse arguments
    parse_args "$@"

    # Validate requirements
    if ! validate_requirements; then
        log_error "Requirements validation failed"
        exit "$EXIT_FATAL"
    fi

    # Setup anacron directories and config
    setup_anacron_directories

    # Select scheduling mode if interactive
    select_mode

    # Setup based on selected mode
    case "$MODE" in
        systemd)
            if ! setup_systemd_anacron; then
                log_error "Failed to setup systemd anacron"
                exit "$EXIT_FATAL"
            fi
            ;;
        cron)
            if ! setup_cron_anacron; then
                log_warn "Failed to setup cron anacron, trying systemd instead"
                MODE="systemd"
                if ! setup_systemd_anacron; then
                    exit "$EXIT_FATAL"
                fi
            fi
            ;;
        *)
            log_error "Unknown mode: $MODE"
            exit "$EXIT_FATAL"
            ;;
    esac

    log_success "Anacron setup completed"
    exit "$EXIT_SUCCESS"
}

# Run main function with all arguments
main "$@"
