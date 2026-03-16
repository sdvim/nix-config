# nix-config

nix-darwin + Home Manager configuration for macOS (Apple Silicon).

## Build

There is a shell alias `rebuild` that wraps the full build command (including sourcing zshrc, reloading tmux, and reloading aerospace). Always nudge the user to run `rebuild` rather than spelling out the full command.

```bash
rebuild
# equivalent to: sudo darwin-rebuild switch --flake ~/nix-config#$(hostname -s) && source ~/.zshrc && tmux source-file ~/.tmux.conf 2>/dev/null; aerospace reload-config 2>/dev/null; true
```

## Architecture

- `flake.nix` — Flake inputs and `mkHost` helper that defines per-host configs (`air`, `mini`)
- `hosts/darwin.nix` — Shared system-level config: macOS defaults, keyboard, dock, finder, homebrew casks, fonts
- `hosts/air.nix` — Air-specific overrides
- `hosts/mini.nix` — Mini-specific overrides (e.g. keyboard remapping)
- `home.nix` — User-level config: packages, git, starship, tmux, ghostty, gh
- `config/` — Raw config files managed via `home.file` (e.g. ghostty)
- `fonts/` — Berkeley Mono Nerd Font TTFs (encrypted via git-crypt)

## git-crypt

Font files in `fonts/` are encrypted transparently. After cloning:

```bash
git-crypt unlock  # requires GPG key 333487C4FFB88C8D
```

To check encryption status:

```bash
git-crypt status
```

## Important: All changes go through Nix

Everything in this repo is declarative. Never edit dotfiles or config files directly in `~` — always make changes in the Nix source files (`home.nix`, `hosts/`, `config/`, etc.) and rebuild. After any change, run the rebuild command above. New files under `config/` must be `git add`ed before rebuilding (flakes only see tracked files).

## Documentation

- nix-darwin options: https://daiderd.com/nix-darwin/manual/index.html
- Home Manager options: https://nix-community.github.io/home-manager/options.xhtml
- Nix language: https://nix.dev/manual/nix/latest/language/
