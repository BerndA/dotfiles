#!/bin/bash
set -euo pipefail

# Configuration
DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
DOTFILES_CONFIG_DIR="$HOME/.config"
DOTFILES_LOG_FILE="$HOME/.dotfiles.install.log"

# Logging
log_info() { echo "ℹ $1"; }
log_success() { echo "✓ $1"; }
log_error() { echo "✗ $1" >&2; }
log_warn() { echo "⚠ $1"; }

# Environment Detection
detect() {
    if command -v nix >/dev/null 2>&1 && command -v home-manager >/dev/null 2>&1 && [[ -d /nix/store ]]; then
        MODE="home-manager"
        log_success "Using home-manager mode"
        return 0
    fi
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        MODE="basic"
        log_success "Using basic mode"
        return 0
    fi
    log_error "No supported environment detected"
    return 1
}

# Package Installation
pkg_installed() { dpkg -q "$1" 2>/dev/null; }
install_pkg() {
    local pkg="$1"
    if pkg_installed "$pkg"; then
        return 0
    fi
    log_info "Installing: $pkg"
    sudo apt-get install -y "$pkg" >/dev/null 2>&1 && return 0
    log_warn "Failed to install: $pkg"
    return 1
}

install_minimal() {
    log_info "Installing required packages"
    install_pkg "git" || true
    install_pkg "curl" || true
    install_pkg "unzip" || true
    install_pkg "zip" || true
    install_pkg "jq" || true
}

# Zsh Setup
setup_zsh() {
    if ! command -v zsh >/dev/null 2>&1; then
        log_info "Installing zsh"
        install_pkg "zsh"
    fi
    
    if [[ ! -f "$HOME/.zshenv" ]]; then
        cat > "$HOME/.zshenv" << 'ZSHENV_EOF'
export SHELL=$(command -v zsh)
export DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"

[ -f "$HOME/.env" ] && source "$HOME/.env"
ZSHENV_EOF
    fi
    
    if [[ ! -f "$HOME/.zprofile" ]]; then
        cat > "$HOME/.zprofile" << 'ZPROFILE_EOF'
[ -f "$HOME/.zshrc" ] && source "$HOME/.zshrc"
ZPROFILE_EOF
    fi
    
    if [[ ! -f "$HOME/.zshrc" ]]; then
        cat > "$HOME/.zshrc" << 'ZSHRC_EOF'
alias ll='ls -lah'
alias la='ls -A'
ZSHRC_EOF
    fi
}

# Environment Files
setup_env() {
    if [[ ! -f "$HOME/.env" ]]; then
        cat > "$HOME/.env" << 'ENV_EOF'
export DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
ENV_EOF
    fi
    
    if [[ ! -d "$HOME/.env.d" ]]; then
        mkdir -p "$HOME/.env.d"
        log_success "Created ~/.env.d"
    fi
}

# Home-manager Setup
setup_home_manager() {
  home-manager switch
}

setup_ssh() {
  mkdir -p "$HOME/.ssh/conf.d" || return 1

  CONFIG_FILE="$HOME/.ssh/config"
  SSH_CONTENT_DIR="${DOTFILES_DIR}/ssh"
  SSH_SOURCE_FILE="$SSH_CONTENT_DIR/main"
  START_MARKER="# --- DOTFILES START ---"
  END_MARKER="# --- DOTFILES END ---"

  # Check if SSH content source file exists
  if [[ ! -f "$SSH_SOURCE_FILE" ]]; then
    log_warn "SSH source file $SSH_SOURCE_FILE not found, skipping SSH config update."
    return 0
  fi

  touch "${CONFIG_FILE}"

  # Check if marker exists
  if grep -qF "$START_MARKER" "$CONFIG_FILE"; then
    # Marker exists, append content after it to ensure latest version, and avoid massive diffing.
    sed -i -e "/$START_MARKER/,/$END_MARKER/{//!d}" -e "/$START_MARKER/r $SSH_SOURCE_FILE" "$CONFIG_FILE"
  else
    # Marker missing, append new section.
    echo "$START_MARKER" >> "$CONFIG_FILE"
    cat "$SSH_SOURCE_FILE" >> "$CONFIG_FILE"
    echo "$END_MARKER" >> "$CONFIG_FILE"
    log_success "Appended SSH config content"
  fi

  cp "${SSH_CONTENT_DIR}/00_default.cfg" "$HOME/.ssh/conf.d/"
}

# Main
main() {
    echo "Starting installation..."
    detect || die "Failed to detect environment"
    
    setup_env
    
    if [[ "$MODE" == "home-manager" ]]; then
        setup_home_manager
    elif [[ "$MODE" == "basic" ]]; then
        install_minimal
    fi
    
    setup_ssh
    setup_zsh
    
    log_success "Installation completed"
}

main "$@"

die() {
    echo "$1" >&2
    exit 1
}
