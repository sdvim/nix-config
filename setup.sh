#!/bin/bash
set -e

# ──────────────────────────────────────────────
# If running via curl|bash, clone the repo first
# ──────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)"
if [[ ! -f "$SCRIPT_DIR/flake.nix" ]]; then
  # Detect username
  USER_NAME="$(whoami)"
  printf "Username for nix config? [%s] " "$USER_NAME"
  read -r input
  USER_NAME="${input:-$USER_NAME}"

  # Detect git directory
  printf "Where should repos live? [~/Git] "
  read -r GIT_DIR
  GIT_DIR="${GIT_DIR:-$HOME/Git}"
  GIT_DIR="${GIT_DIR/#\~/$HOME}"
  mkdir -p "$GIT_DIR"

  FLAKE_DIR="$GIT_DIR/nix-config"
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

  # Patch flake.nix with actual values
  sed -i '' "s|userName = \".*\"|userName = \"$USER_NAME\"|" "$FLAKE_DIR/flake.nix"
  sed -i '' "s|flakeDir = \".*\"|flakeDir = \"$FLAKE_DIR\"|" "$FLAKE_DIR/flake.nix"

  exec bash "$FLAKE_DIR/setup.sh" "$@"
fi

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
# Full Disk Access check
# ──────────────────────────────────────────────
if ! plutil -lint /Library/Preferences/com.apple.TimeMachine.plist >/dev/null 2>&1; then
  TERMINAL="${TERM_PROGRAM:-unknown terminal}"
  warn "Full Disk Access is required but $TERMINAL does not have it."
  if ask "Open System Settings to grant Full Disk Access?"; then
    open "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_AllFiles" 2>/dev/null \
      || open "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles" 2>/dev/null
  fi
  warn "Please grant Full Disk Access to $TERMINAL, then re-run this script."
  exit 1
fi

info "Full Disk Access confirmed."

# ──────────────────────────────────────────────
# Host detection
# ──────────────────────────────────────────────
KNOWN_HOSTS=($(grep 'darwinConfigurations\."' "$SCRIPT_DIR/flake.nix" | sed 's/.*darwinConfigurations\."\([^"]*\)".*/\1/'))

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

# ──────────────────────────────────────────────
# Repo location migration
# ──────────────────────────────────────────────
EXPECTED_DIR="$(sed -n 's/.*flakeDir = "\(.*\)";/\1/p' "$FLAKE_DIR/flake.nix")"
if [[ -n "$EXPECTED_DIR" && "$FLAKE_DIR" != "$EXPECTED_DIR" ]]; then
  warn "Repo is at $FLAKE_DIR but flake.nix expects $EXPECTED_DIR"
  if ask "Move repo to $EXPECTED_DIR?"; then
    mkdir -p "$(dirname "$EXPECTED_DIR")"
    mv "$FLAKE_DIR" "$EXPECTED_DIR"
    info "Moved to $EXPECTED_DIR"

    # Migrate Claude Code sessions to the new project path
    OLD_CLAUDE_DIR="$HOME/.claude/projects/$(echo "$FLAKE_DIR" | tr '/' '-')"
    NEW_CLAUDE_DIR="$HOME/.claude/projects/$(echo "$EXPECTED_DIR" | tr '/' '-')"
    if [[ -d "$OLD_CLAUDE_DIR" ]]; then
      mkdir -p "$NEW_CLAUDE_DIR"
      cp -rn "$OLD_CLAUDE_DIR"/ "$NEW_CLAUDE_DIR"/
      info "Migrated Claude Code sessions to $NEW_CLAUDE_DIR"
    fi

    exec bash "$EXPECTED_DIR/setup.sh" "$@"
  else
    skip
  fi
fi

FLAKE_REF="$FLAKE_DIR#$HOST"

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
# 5. Build and switch
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
# 6. GitHub CLI login
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
# 7. SSH key setup + GitHub verification
# ──────────────────────────────────────────────
if [[ ! -f "$HOME/.ssh/id_ed25519" ]]; then
  if ask "Generate SSH key?"; then
    ssh-keygen -t ed25519 -C "$(hostname -s)" -f "$HOME/.ssh/id_ed25519" -N ""
    info "SSH key generated."
  else
    skip
  fi
fi

if [[ -f "$HOME/.ssh/id_ed25519.pub" ]]; then
  # Ensure github.com is in known_hosts
  if ! grep -q github.com "$HOME/.ssh/known_hosts" 2>/dev/null; then
    ssh-keyscan github.com >> "$HOME/.ssh/known_hosts" 2>/dev/null
  fi

  # Check if local key is registered on GitHub
  LOCAL_KEY="$(awk '{print $2}' "$HOME/.ssh/id_ed25519.pub")"
  if gh ssh-key list 2>/dev/null | grep -q "$LOCAL_KEY"; then
    info "SSH key is already registered on GitHub."
  else
    if ask "Add SSH key to GitHub?"; then
      gh ssh-key add "$HOME/.ssh/id_ed25519.pub" --title "$(hostname -s)"
      info "SSH key added to GitHub."
    else
      skip
    fi
  fi

  # Verify SSH connection to GitHub
  if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    info "SSH connection to GitHub verified."
  else
    warn "SSH connection to GitHub failed. You may need to troubleshoot manually."
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
# 8. GPG key import from 1Password
# ──────────────────────────────────────────────
GPG_KEY_ID="333487C4FFB88C8D"
if gpg --list-secret-keys "$GPG_KEY_ID" &>/dev/null; then
  info "GPG key $GPG_KEY_ID already imported."
else
  if ask "Import GPG key from 1Password?"; then
    # TODO: Migrate GPG key to 1Password (Personal vault) and implement:
    #   1. Sign in:        eval "$(op signin)"
    #   2. Fetch key:      op document get "GPG Secret Key" --out-file "$GPG_KEY_FILE"
    #   3. Get passphrase: op item get "GPG Secret Key" --fields label=Passphrase
    #   4. Import + preset passphrase in gpg-agent (same as before)
    warn "GPG key import from 1Password is not yet implemented."
    warn "Please import your GPG key manually for now."
  else
    skip
  fi
fi

# ──────────────────────────────────────────────
# 9. git-crypt unlock
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
# 10. Install Claude Code
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
