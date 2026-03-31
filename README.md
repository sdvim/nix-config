# nix-config

nix-darwin + Home Manager configuration for macOS (Apple Silicon).

## Bootstrap

On a fresh Mac, run:

```bash
bash <(curl -sL https://raw.githubusercontent.com/sdvim/nix-config/main/setup.sh)
```

This will clone the repo, install Nix + Homebrew, and build the system config. The host is auto-detected from `hostname -s`, or pass it explicitly:

```bash
bash <(curl -sL https://raw.githubusercontent.com/sdvim/nix-config/main/setup.sh) mini
```

## Hosts

| Host | Machine | Flake target |
|------|---------|--------------|
| `air` | MacBook Air | `#air` |
| `mini` | Mac Mini | `#mini` |

## Rebuild

```bash
rebuild  # alias auto-detects hostname
# or manually:
sudo darwin-rebuild switch --flake ~/Git/nix-config#<hostname>
```

## Architecture

- `flake.nix` — Flake inputs and `mkHost` helper that defines per-host configs (`air`, `mini`)
- `hosts/darwin.nix` — Shared system-level config: macOS defaults, keyboard, dock, finder, homebrew casks, fonts
- `hosts/air.nix` — Air-specific overrides
- `hosts/mini.nix` — Mini-specific overrides (e.g. keyboard remapping)
- `home.nix` — User-level config: packages, git, starship, tmux, ghostty, gh
- `config/` — Raw config files managed via `home.file` (e.g. ghostty, nvim)
- `fonts/` — Berkeley Mono Nerd Font TTFs (encrypted via git-crypt)
- `setup.sh` — Bootstrap script for fresh machines (supports `curl | bash`)

## git-crypt

Font files in `fonts/` are encrypted. After cloning:

```bash
git-crypt unlock  # requires GPG key 333487C4FFB88C8D
```

## Manual Steps

Some setup can't be automated through Nix. On a fresh machine:

1. **1Password → Helium** — Connect Helium as a browser in 1Password (Settings → Browser → Add Browser → select Helium.app)
2. **Helium extensions** — Install [Vimium](https://chromewebstore.google.com/detail/vimium/dbepggeogbaibhgnhhndojpepiihcmeb) and [1Password](https://chromewebstore.google.com/detail/1password-–-password-mana/aeblfdkhhhdcdjpifhhbdiojplfjncoa) extensions
3. **Vimium settings** — Open the [Vimium options page](chrome-extension://dbepggeogbaibhgnhhndojpepiihcmeb/pages/options.html), scroll to the bottom, click "Show Advanced Options", then "Backup and Restore" → import from `config/vimium/vimium-options.json`
4. **Helium web apps** — Install Google Meet as an app via Helium
