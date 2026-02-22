{ pkgs, ... }: {
  home.username = "stevedv";
  home.homeDirectory = "/Users/stevedv";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;

  # ──────────────────────────────────────────────
  # Packages (replaces `brew install` for CLI tools)
  # ──────────────────────────────────────────────
  home.packages = with pkgs; [
    # Modern CLI replacements
    bat
    eza
    fd
    ripgrep
    fzf
    jq
    tealdeer

    # Shell tools
    zoxide
    starship
    tmux

    # Development
    gh
    gnupg
    git-crypt
    codex
    bitwarden-cli

    neovim
    fnm

    # TODO: uncomment after uninstalling brew claude-code
    # Then run: nix flake update claude-code && sudo darwin-rebuild switch --flake ~/nix-config#air
    # claude-code  # via inputs.claude-code flake
  ];

  # ──────────────────────────────────────────────
  # Shell aliases
  # ──────────────────────────────────────────────
  home.shellAliases = {
    rebuild = "sudo darwin-rebuild switch --flake ~/nix-config#air";
  };

  # ──────────────────────────────────────────────
  # Git (migrated from .gitconfig)
  # ──────────────────────────────────────────────
  programs.git = {
    enable = true;
    signing = {
      key = "333487C4FFB88C8D";
      signByDefault = true;
      format = "openpgp";
    };
    settings = {
      user.name = "Steve Della Valentina";
      user.email = "s.dellavalentina@gmail.com";
      pull.rebase = true;
      core.editor = "nvim";
      core.hooksPath = "~/nix-config/git-hooks";
      init.defaultBranch = "main";
    };
  };

  # ──────────────────────────────────────────────
  # Starship prompt (migrated from .config/starship.toml)
  # ──────────────────────────────────────────────
  # Note: Your setup uses two configs (unicode vs ASCII for Terminus).
  # Home Manager manages the default one. The ASCII fallback can stay
  # as a raw file or be handled via shell logic.
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      add_newline = true;
      git_status = {
        ahead = "⇡\${count}";
        behind = "⇣\${count}";
        diverged = "⇡\${ahead_count}⇣\${behind_count}";
      };
      gcloud.disabled = true;
    };
  };

  # ──────────────────────────────────────────────
  # Tmux (migrated from .tmux.conf)
  # ──────────────────────────────────────────────
  programs.tmux = {
    enable = true;
    mouse = true;
    historyLimit = 50000;
    terminal = "tmux-256color";
    extraConfig = ''
      set -g status off
      set -ga terminal-overrides ",xterm*:Tc"
    '';
  };

  # ──────────────────────────────────────────────
  # Raw config files (no native HM module)
  # Uncomment as you migrate each one.
  # ──────────────────────────────────────────────

  home.file.".config/ghostty/config".source = ./config/ghostty/config;

  # Claude Code — baseline settings (read-only via Nix store symlink)
  # Runtime overrides go in ~/.claude/settings.local.json (unmanaged)
  home.file.".claude/settings.json".text = builtins.toJSON {
    skipDangerousModePermissionPrompt = true;
  };
  # home.file.".config/aerospace/aerospace.toml".source = ./config/aerospace/aerospace.toml;

  # ──────────────────────────────────────────────
  # GitHub CLI
  # ──────────────────────────────────────────────
  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
    };
  };
}
