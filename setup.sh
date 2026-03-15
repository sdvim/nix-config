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
KNOWN_HOSTS=("air" "mini")

if [[ -n "$1" ]]; then
  HOST="$1"
else
  HOST="$(hostname -s)"
fi

# Validate host; prompt to pick if auto-detected host is unknown
host_valid=false
for h in "${KNOWN_HOSTS[@]}"; do
  [[ "$HOST" == "$h" ]] && host_valid=true
done

if ! $host_valid; then
  echo "Detected hostname '$HOST' is not a known host."
  echo "Pick a host to set up:"
  select HOST in "${KNOWN_HOSTS[@]}"; do
    [[ -n "$HOST" ]] && break
    echo "Invalid selection. Try again."
  done
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

# ──────────────────────────────────────────────
# 7. GitHub CLI login
# ──────────────────────────────────────────────
if gh auth status &>/dev/null; then
  info "GitHub CLI is already authenticated."
else
  if ask "Log in to GitHub CLI?"; then
    gh auth login
    info "GitHub CLI authenticated."
  else
    skip
  fi
fi

# ──────────────────────────────────────────────
# 8. SSH key generation + GitHub upload
# ──────────────────────────────────────────────
if [[ -f "$HOME/.ssh/id_ed25519" ]]; then
  info "SSH key already exists."
else
  if ask "Generate SSH key and add to GitHub?"; then
    ssh-keygen -t ed25519 -C "$(hostname -s)" -f "$HOME/.ssh/id_ed25519" -N ""
    ssh-keyscan github.com >> "$HOME/.ssh/known_hosts" 2>/dev/null
    gh ssh-key add "$HOME/.ssh/id_ed25519.pub" --title "$(hostname -s)"
    info "SSH key generated and added to GitHub."
  else
    skip
  fi
fi

# Switch nix-config remote to SSH if still HTTPS
CURRENT_REMOTE="$(git -C "$FLAKE_DIR" remote get-url origin)"
if [[ "$CURRENT_REMOTE" == https://* ]]; then
  git -C "$FLAKE_DIR" remote set-url origin git@github.com:sdvim/nix-config.git
  info "Switched nix-config remote to SSH."
else
  info "nix-config remote is already SSH."
fi

# ──────────────────────────────────────────────
# 9. GPG key import from Bitwarden
# ──────────────────────────────────────────────
GPG_KEY_ID="333487C4FFB88C8D"
if gpg --list-secret-keys "$GPG_KEY_ID" &>/dev/null; then
  info "GPG key $GPG_KEY_ID already imported."
else
  if ask "Import GPG key from Bitwarden?"; then
    # Login/unlock Bitwarden
    if ! bw login --check &>/dev/null; then
      export BW_SESSION="$(bw login --raw)"
    fi
    if [[ -z "$BW_SESSION" ]]; then
      export BW_SESSION="$(bw unlock --raw)"
    fi

    # Find the GPG key item
    BW_ITEM="$(bw list items --search 'GPG Secret Key' --session "$BW_SESSION" | jq -r '.[0]')"
    BW_ITEM_ID="$(echo "$BW_ITEM" | jq -r '.id')"

    # Get the key attachment and passphrase
    GPG_KEY_FILE="$(mktemp)"
    bw get attachment "secret-key.asc" --itemid "$BW_ITEM_ID" --output "$GPG_KEY_FILE" --session "$BW_SESSION"
    GPG_PASSPHRASE="$(echo "$BW_ITEM" | jq -r '.fields[] | select(.name == "Passphrase") | .value')"

    # Import the key
    echo "$GPG_PASSPHRASE" | gpg --batch --passphrase-fd 0 --import "$GPG_KEY_FILE"
    rm -f "$GPG_KEY_FILE"

    # Pre-cache passphrase in gpg-agent
    GPG_KEYGRIP="$(gpg --with-keygrip --list-secret-keys "$GPG_KEY_ID" | grep -m1 Keygrip | awk '{print $3}')"
    echo "$GPG_PASSPHRASE" | /usr/local/libexec/gpg-preset-passphrase --preset "$GPG_KEYGRIP"

    info "GPG key imported and passphrase cached."
  else
    skip
  fi
fi

# ──────────────────────────────────────────────
# 10. git-crypt unlock
# ──────────────────────────────────────────────
if git -C "$FLAKE_DIR" crypt status 2>/dev/null | grep -q "encrypted:"; then
  if ask "Unlock git-crypt (for encrypted fonts)?"; then
    git -C "$FLAKE_DIR" crypt unlock
    info "git-crypt unlocked."
  else
    skip
  fi
else
  info "git-crypt already unlocked (or no encrypted files)."
fi

# ──────────────────────────────────────────────
# 11. Install Claude Code
# ──────────────────────────────────────────────
if command -v claude &>/dev/null; then
  info "Claude Code is already installed."
else
  if ask "Install Claude Code (via npm)?"; then
    npm install -g @anthropic-ai/claude-code
    info "Claude Code installed."
  else
    skip
  fi
fi

printf "\n${bold}${green}Setup finished.${reset}\n"
