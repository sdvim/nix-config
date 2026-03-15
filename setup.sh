#!/bin/bash
set -e

# ──────────────────────────────────────────────
# If running via curl|bash, clone the repo first
# ──────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)"
if [[ ! -f "$SCRIPT_DIR/flake.nix" ]]; then
  FLAKE_DIR="$HOME/nix-config"
  if [[ ! -d "$FLAKE_DIR" ]]; then
    echo "Cloning nix-config to $FLAKE_DIR..."
    if command -v git &>/dev/null; then
      git clone https://github.com/sdvim/nix-config.git "$FLAKE_DIR"
    elif command -v xcode-select &>/dev/null; then
      xcode-select --install 2>/dev/null || true
      echo "Waiting for Xcode CLT install to complete..."
      until command -v git &>/dev/null; do sleep 5; done
      git clone https://github.com/sdvim/nix-config.git "$FLAKE_DIR"
    else
      echo "Error: git is not available and cannot be installed automatically."
      exit 1
    fi
  fi
  exec bash "$FLAKE_DIR/setup.sh" "$@"
fi

# ──────────────────────────────────────────────
# Host detection
# ──────────────────────────────────────────────
HOST="${1:-$(hostname -s)}"
KNOWN_HOSTS=("air" "mini")

host_valid=false
for h in "${KNOWN_HOSTS[@]}"; do
  [[ "$HOST" == "$h" ]] && host_valid=true
done

if ! $host_valid; then
  echo "Error: unknown host '$HOST'. Known hosts: ${KNOWN_HOSTS[*]}"
  echo "Usage: $0 [hostname]"
  exit 1
fi

FLAKE_DIR="$(cd "$(dirname "$0")" && pwd)"
FLAKE_REF="$FLAKE_DIR#$HOST"

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

info "Setting up host: $HOST"

# ──────────────────────────────────────────────
# 1. Install Nix
# ──────────────────────────────────────────────
if command -v nix &>/dev/null; then
  info "Nix is already installed."
else
  if ask "Install Nix?"; then
    sh <(curl -L https://nixos.org/nix/install)
    # Source nix-daemon so nix is available in this shell
    if [[ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
      . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    fi
    info "Nix installed."
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
