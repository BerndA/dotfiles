#!/bin/bash
set -euo pipefail

# Enhanced Dotfiles Installer
# Simplified to two modes: home-manager (Nix) or basic (standard Linux)
#
# Mode 1: Home-Manager (when nix & home-manager already installed)
# - Assumes all configuration managed via flake.nix + home-manager
# - Links flake.nix, enables nix flakes
# - Minimal additional setup (no installation of home-manager)
# - Falls back to basic mode if home-manager not available
#
# Mode 2: Basic (fallback for standard Linux)
# - Installs minimal required packages (git, curl, zsh, etc.) via apt
# - Creates basic shell configuration
# - No complex package management

# Configuration
DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
DOTFILES_CONFIG_DIR="$HOME/.config"
DOTFILES_LOG_FILE="$HOME/.dotfiles.install.log"
DOTFILES_SYSTEMD_USER="$HOME/.config/systemd/user"

# Flags
INTERACTIVE="${INTERACTIVE:-true}"
SKIP_OPTIONAL="${SKIP_OPTIONAL:-false}"
VERBOSE="${VERBOSE:-false}"

# Exit codes
EXIT_SUCCESS=0
EXIT_FATAL=1
EXIT_WARNINGS=2
EXIT_PARTIAL=3

# Tracking
INSTALLED_PACKAGES=()
SKIPPED_PACKAGES=()
FAILED_OPERATIONS=()
MODE=""  # "home-manager" or "basic"

# ============================================================================
# Logging and output functions
# ============================================================================

log() {
    local message="$1"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $message" | tee -a "$DOTFILES_LOG_FILE"
}

log_info() {
    echo "ℹ  $1"
    echo "ℹ  $1" >> "$DOTFILES_LOG_FILE"
}

log_success() {
    echo "✓ $1"
    echo "✓ $1" >> "$DOTFILES_LOG_FILE"
}

log_warn() {
    echo "⚠ $1"
    echo "⚠ $1" >> "$DOTFILES_LOG_FILE"
}

log_error() {
    echo "✗ $1"
    echo "✗ $1" >> "$DOTFILES_LOG_FILE"
}

verbose_log() {
    if [[ "$VERBOSE" == "true" ]]; then
        log_info "$1"
    fi
}

# ============================================================================
# Environment Detection
# ============================================================================

detect_home_manager() {
    # Check if nix and home-manager are already available (no installation)
    if command -v nix &> /dev/null && command -v home-manager &> /dev/null && [[ -d "/nix/store" ]]; then
        MODE="home-manager"
        log_success "Home-manager environment detected (nix + home-manager available)"
        return 0
    fi
    return 1
}

detect_basic_linux() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        MODE="basic"
        log_success "Basic Linux environment detected"
        return 0
    fi
    return 1
}

# ============================================================================
# Validation
# ============================================================================

validate_requirements() {
    log_info "Validating requirements..."
    
    # Check writable directories
    if [[ ! -w "$HOME" ]]; then
        log_error "Home directory $HOME is not writable"
        return 1
    fi
    
    # Check for required tools
    local required_tools=("bash" "mkdir" "cp")
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            log_error "Required tool not found: $tool"
            return 1
        fi
    done
    
    log_success "All requirements validated"
    return 0
}

# ============================================================================
# Package Management (Basic Mode Only)
# ============================================================================

check_apt_available() {
    command -v apt-get &> /dev/null && command -v dpkg &> /dev/null
}

is_package_installed() {
    local package="$1"
    if check_apt_available; then
        dpkg -l | grep -q "^ii.*$package" && return 0
    fi
    return 1
}

install_package() {
    local package="$1"
    
    if is_package_installed "$package"; then
        verbose_log "Package already installed: $package"
        return 0
    fi
    
    if ! check_apt_available; then
        log_warn "apt not available, skipping package: $package"
        SKIPPED_PACKAGES+=("$package")
        return 0
    fi
    
    log_info "Installing package: $package"
    if sudo apt-get install -y "$package" >> "$DOTFILES_LOG_FILE" 2>&1; then
        INSTALLED_PACKAGES+=("$package")
        log_success "Installed: $package"
        return 0
    else
        log_error "Failed to install: $package"
        FAILED_OPERATIONS+=("install:$package")
        return 1
    fi
}

install_basic_packages() {
    log_info "Installing minimal required packages..."
    
    local required=("git" "curl" "unzip" "zip" "jq" "zsh")
    
    for package in "${required[@]}"; do
        install_package "$package" || true
    done
}

# ============================================================================
# Zsh Shell Setup
# ============================================================================

setup_zsh() {
    log_info "Setting up Zsh shell..."
    
    # Install zsh if not present
    if ! command -v zsh &> /dev/null; then
        log_info "Zsh not found, installing..."
        install_package "zsh"
    fi
    
    # Create .zshenv
    if [[ ! -f "$HOME/.zshenv" ]]; then
        log_info "Creating ~/.zshenv"
        cat > "$HOME/.zshenv" << 'ZSHENV_EOF'
# Zsh environment configuration
export SHELL=$(command -v zsh)
export DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
export DOTFILES_CONFIG_DIR="${DOTFILES_CONFIG_DIR:-$HOME/.config}"

# Load environment files
if [[ -f "$HOME/.env" ]]; then
    source "$HOME/.env"
fi

# Load all env.d/* files in order
if [[ -d "$HOME/.env.d" ]]; then
    for env_file in "$HOME/.env.d"/*.sh; do
        [[ -f "$env_file" ]] && source "$env_file"
    done
fi
ZSHENV_EOF
        log_success "Created ~/.zshenv"
    else
        verbose_log "~/.zshenv already exists"
    fi
    
    # Create .zprofile
    if [[ ! -f "$HOME/.zprofile" ]]; then
        log_info "Creating ~/.zprofile"
        cat > "$HOME/.zprofile" << 'ZPROFILE_EOF'
# Zsh profile configuration
if [[ -f "$HOME/.zshrc" ]]; then
    source "$HOME/.zshrc"
fi
ZPROFILE_EOF
        log_success "Created ~/.zprofile"
    else
        verbose_log "~/.zprofile already exists"
    fi
    
    # Create .zshrc if not present
    if [[ ! -f "$HOME/.zshrc" ]]; then
        log_info "Creating ~/.zshrc"
        cat > "$HOME/.zshrc" << 'ZSHRC_EOF'
# Zsh interactive shell configuration

# Set prompt (simple fallback)
PS1='%n@%m:%~$ '

# Useful aliases
alias ll='ls -lah'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
ZSHRC_EOF
        log_success "Created ~/.zshrc"
    else
        verbose_log "~/.zshrc already exists"
    fi
}

# ============================================================================
# Home-Manager Setup
# ============================================================================

setup_home_manager() {
    log_info "Setting up home-manager environment..."
    
    # Link flake.nix if present in dotfiles
    if [[ -f "$DOTFILES_DIR/flake.nix" ]]; then
        if [[ ! -f "$HOME/.flake.nix" ]]; then
            ln -s "$DOTFILES_DIR/flake.nix" "$HOME/.flake.nix"
            log_success "Linked flake.nix"
        else
            verbose_log "~/.flake.nix already exists"
        fi
    fi
    
    # Enable nix flakes in user config
    if [[ ! -d "$DOTFILES_CONFIG_DIR/nix" ]]; then
        mkdir -p "$DOTFILES_CONFIG_DIR/nix"
        log_success "Created ~/.config/nix"
    fi
    
    # Add nix to PATH if not already there
    if ! grep -q "nix-profile" "$HOME/.zshenv" 2>/dev/null; then
        cat >> "$HOME/.zshenv" << 'NIX_PATH_EOF'

# Nix setup
if [[ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ]]; then
    source "$HOME/.nix-profile/etc/profile.d/nix.sh"
fi
NIX_PATH_EOF
        log_success "Added Nix to PATH"
    fi
    
    log_info "Home-manager setup complete"
    log_info "Next step: run 'home-manager switch' to apply configuration"
}

# ============================================================================
# Basic Mode Setup
# ============================================================================

setup_basic_mode() {
    log_info "Setting up basic Linux environment..."
    
    # Install minimal packages
    install_basic_packages
    
    # Setup zsh
    setup_zsh
    
    # Create basic config directories
    mkdir -p "$DOTFILES_CONFIG_DIR/bash"
    mkdir -p "$DOTFILES_CONFIG_DIR/zsh"
    mkdir -p "$DOTFILES_CONFIG_DIR/git"
    
    # Create .bashrc if not present
    if [[ ! -f "$HOME/.bashrc" ]]; then
        log_info "Creating ~/.bashrc"
        cat > "$HOME/.bashrc" << 'BASHRC_EOF'
# Bash configuration
export SHELL=$(command -v bash)
export DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
export DOTFILES_CONFIG_DIR="${DOTFILES_CONFIG_DIR:-$HOME/.config}"

# Load environment files
if [[ -f "$HOME/.env" ]]; then
    source "$HOME/.env"
fi

# Load all env.d/* files
if [[ -d "$HOME/.env.d" ]]; then
    for env_file in "$HOME/.env.d"/*.sh; do
        [[ -f "$env_file" ]] && source "$env_file"
    done
fi

# Aliases
alias ll='ls -lah'
alias la='ls -A'
BASHRC_EOF
        log_success "Created ~/.bashrc"
    fi
    
    log_info "Basic mode setup complete"
}

# ============================================================================
# Environment File Setup
# ============================================================================

setup_environment() {
    log_info "Setting up environment variables..."
    
    # Create .env if not present
    if [[ ! -f "$HOME/.env" ]]; then
        cat > "$HOME/.env" << 'ENV_EOF'
# Dotfiles environment configuration
export DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
export DOTFILES_CONFIG_DIR="${DOTFILES_CONFIG_DIR:-$HOME/.config}"
export DOTFILES_SYSTEMD_USER="${DOTFILES_SYSTEMD_USER:-$HOME/.config/systemd/user}"
ENV_EOF
        log_success "Created ~/.env"
    else
        verbose_log "~/.env already exists"
    fi
    
    # Create .env.d directory
    if [[ ! -d "$HOME/.env.d" ]]; then
        mkdir -p "$HOME/.env.d"
        log_success "Created ~/.env.d"
    fi
}

# ============================================================================
# Cleanup and Summary
# ============================================================================

print_summary() {
    local exit_code="$1"
    
    echo ""
    echo "============================================"
    echo "Installation Summary"
    echo "============================================"
    echo "Mode: $MODE"
    
    if [[ "$MODE" == "basic" ]]; then
        echo "Installed Packages: ${#INSTALLED_PACKAGES[@]}"
        [[ ${#INSTALLED_PACKAGES[@]} -gt 0 ]] && printf '  • %s\n' "${INSTALLED_PACKAGES[@]}"
        echo ""
        echo "Skipped Packages: ${#SKIPPED_PACKAGES[@]}"
        [[ ${#SKIPPED_PACKAGES[@]} -gt 0 ]] && printf '  • %s\n' "${SKIPPED_PACKAGES[@]}"
        echo ""
        echo "Failed Operations: ${#FAILED_OPERATIONS[@]}"
        [[ ${#FAILED_OPERATIONS[@]} -gt 0 ]] && printf '  • %s\n' "${FAILED_OPERATIONS[@]}"
    fi
    
    echo ""
    echo "Log file: $DOTFILES_LOG_FILE"
    echo "============================================"
    
    case "$exit_code" in
        "$EXIT_SUCCESS")
            echo "✓ Installation completed successfully"
            ;;
        "$EXIT_WARNINGS")
            echo "⚠ Installation completed with warnings"
            ;;
        "$EXIT_PARTIAL")
            echo "⚠ Installation completed with partial success"
            ;;
        "$EXIT_FATAL")
            echo "✗ Installation failed"
            ;;
    esac
    echo "============================================"
}

trap_exit() {
    local exit_code=$?
    
    if [[ $exit_code -ne 0 ]]; then
        log_error "Installation failed with exit code $exit_code"
        [[ ${#FAILED_OPERATIONS[@]} -gt 0 ]] && echo "Failed operations:" >&2 && printf '  • %s\n' "${FAILED_OPERATIONS[@]}" >&2
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
            --quiet)
                INTERACTIVE="false"
                ;;
            --interactive)
                INTERACTIVE="true"
                ;;
            --skip-optional)
                SKIP_OPTIONAL="true"
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
Enhanced Dotfiles Installer

Usage: ./install.sh [OPTIONS]

Modes (auto-detected):
  • home-manager: Uses existing Nix home-manager (nix + home-manager must be installed)
  • basic: Falls back to standard Linux package management (apt/dpkg)

Options:
  --quiet              Non-interactive mode
  --interactive        Interactive mode (default outside CI)
  --skip-optional      Skip optional packages (basic mode only)
  --verbose            Enable verbose logging
  --help               Show this help message

Examples:
  ./install.sh              # Auto-detect and install
  ./install.sh --quiet      # Non-interactive installation
  ./install.sh --verbose    # Verbose output

Requirements:
  • home-manager mode: nix and home-manager must already be installed
  • basic mode: apt/dpkg on Linux (sudo access for package installation)

Next Steps:
  • home-manager mode: run 'home-manager switch'
  • basic mode: configure shell and additional tools as needed

HELP_EOF
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
    # Initialize
    mkdir -p "$(dirname "$DOTFILES_LOG_FILE")"
    trap trap_exit EXIT
    
    log "Starting dotfiles installation..."
    log "Script version: 2.0 (simplified)"
    
    # Parse arguments
    parse_args "$@"
    
    # Set interactive mode based on environment
    if [[ -n "${CI:-}" || -n "${DEVCONTAINER:-}" ]]; then
        INTERACTIVE="false"
    fi
    
    # Validate requirements
    if ! validate_requirements; then
        log_error "Requirements validation failed"
        exit "$EXIT_FATAL"
    fi
    
    # Detect mode
    if ! detect_home_manager; then
        if ! detect_basic_linux; then
            log_error "Could not detect supported environment"
            exit "$EXIT_FATAL"
        fi
    fi
    
    log_info "Using $MODE mode"
    
    # Setup common infrastructure
    setup_environment
    setup_zsh
    
    # Setup based on mode
    if [[ "$MODE" == "home-manager" ]]; then
        setup_home_manager
    elif [[ "$MODE" == "basic" ]]; then
        setup_basic_mode
    fi
    
    log_success "Dotfiles installation completed"
    
    # Determine exit code
    local exit_code="$EXIT_SUCCESS"
    if [[ ${#FAILED_OPERATIONS[@]} -gt 0 ]]; then
        [[ ${#SKIPPED_PACKAGES[@]} -gt 0 ]] && exit_code="$EXIT_PARTIAL" || exit_code="$EXIT_WARNINGS"
    elif [[ ${#SKIPPED_PACKAGES[@]} -gt 0 ]]; then
        exit_code="$EXIT_WARNINGS"
    fi
    
    exit "$exit_code"
}

# Run main function with all arguments
main "$@"
