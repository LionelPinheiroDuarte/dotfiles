#!/usr/bin/env bash
set -euo pipefail

DOTFILES_REPO="https://github.com/LionelPinheiroDuarte/dotfiles.git"
DOTFILES_DIR="$HOME/repos/github/dotfiles"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()    { echo -e "${GREEN}[bootstrap]${NC} $*"; }
warning() { echo -e "${YELLOW}[bootstrap]${NC} $*"; }
error()   { echo -e "${RED}[bootstrap]${NC} $*" >&2; exit 1; }

# Checks
[[ "$(id -u)" -eq 0 ]] && error "Do not run as root. Run as your regular user (sudo will be prompted)."
command -v apt-get &>/dev/null || error "This script requires a Debian-based system (apt not found)."

info "Installing Ansible and Git..."
sudo apt-get update -qq
sudo apt-get install -y ansible-core git

info "Cloning dotfiles..."
if [[ -d "$DOTFILES_DIR" ]]; then
    warning "Dotfiles already present at $DOTFILES_DIR — skipping clone."
else
    mkdir -p "$HOME/repos/github"
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
fi

info "Running Ansible playbook..."
cd "$DOTFILES_DIR"
ansible-playbook ansible/playbook.yml -i ansible/inventory.ini -K "$@"

info "Done. Open a new shell or source ~/.bashrc to apply changes."
