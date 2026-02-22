#!/bin/bash
set -e

FLAKE_DIR="$(cd "$(dirname "$0")" && pwd)"
FLAKE_REF="$FLAKE_DIR#air"

# Colors
bold='\033[1m'
green='\033[0;32m'
yellow='\033[0;33m'
red='\033[0;31m'
reset='\033[0m'

step=0

ask() {
  step=$((step + 1))
  printf "\n${bold}${step}. $1 [y/n]${reset} "
  read -r answer
  [[ "$answer" =~ ^[Yy]$ ]]
}

info()  { printf "${green}>>>${reset} %s\n" "$1"; }
warn()  { printf "${yellow}>>>${reset} %s\n" "$1"; }
skip()  { printf "    Skipped.\n"; }

# ──────────────────────────────────────────────
# 1. Install Nix
# ──────────────────────────────────────────────
if command -v nix &>/dev/null; then
  info "Nix is already installed."
else
  if ask "Install Nix?"; then
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
    info "Nix installed. You may need to restart your shell."
  else
    skip
  fi
fi

# ──────────────────────────────────────────────
# 2. Install Homebrew
# ──────────────────────────────────────────────
if command -v brew &>/dev/null; then
  info "Homebrew is already installed."
else
  if ask "Install Homebrew?"; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Add brew to PATH for the rest of this script
    if [[ -f /opt/homebrew/bin/brew ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    info "Homebrew installed."
  else
    skip
  fi
fi

# ──────────────────────────────────────────────
# 3. Move conflicting /etc files
# ──────────────────────────────────────────────
etc_conflicts=()
for f in /etc/bashrc /etc/zshrc; do
  if [[ -f "$f" && ! -L "$f" ]]; then
    etc_conflicts+=("$f")
  fi
done

if [[ ${#etc_conflicts[@]} -gt 0 ]]; then
  if ask "Rename conflicting files (${etc_conflicts[*]}) so nix-darwin can manage them?"; then
    for f in "${etc_conflicts[@]}"; do
      sudo mv "$f" "${f}.before-nix-darwin"
      info "Moved $f -> ${f}.before-nix-darwin"
    done
  else
    skip
  fi
else
  info "No conflicting /etc files found."
fi

# ──────────────────────────────────────────────
# 4. Create Screenshots directory
# ──────────────────────────────────────────────
if [[ -d "$HOME/Screenshots" ]]; then
  info "~/Screenshots already exists."
else
  if ask "Create ~/Screenshots directory (used by screencapture config)?"; then
    mkdir -p "$HOME/Screenshots"
    info "Created ~/Screenshots."
  else
    skip
  fi
fi

# ──────────────────────────────────────────────
# 5. Grant Full Disk Access reminder
# ──────────────────────────────────────────────
if ask "Do you need a reminder to grant Full Disk Access to your terminal? (required for universalaccess defaults)"; then
  warn "Open: System Settings > Privacy & Security > Full Disk Access"
  warn "Add your terminal app (Terminal, Ghostty, iTerm2, etc.)"
  printf "    Press Enter when done... "
  read -r
else
  skip
fi

# ──────────────────────────────────────────────
# 6. Build and switch
# ──────────────────────────────────────────────
if ask "Run darwin-rebuild switch now?"; then
  if command -v darwin-rebuild &>/dev/null; then
    info "Running: sudo darwin-rebuild switch --flake $FLAKE_REF"
    sudo darwin-rebuild switch --flake "$FLAKE_REF"
  else
    info "Running initial build via nix run..."
    sudo nix --extra-experimental-features "nix-command flakes" run nix-darwin -- switch --flake "$FLAKE_REF"
  fi
  info "Build complete!"
else
  skip
fi

printf "\n${bold}${green}Setup finished.${reset}\n"
