{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [ ./claude.nix ];

  home.username = "stevedv";
  home.homeDirectory = "/Users/stevedv";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    _1password-cli
    ast-grep
    bat
    biome
    bitwarden-cli
    bun
    colima
    docker-client
    eas-cli
    eza
    fd
    # fzf installed via programs.fzf below
    gh
    git-crypt
    gnupg
    jq
    kanata
    lazygit
    lua5_1
    luarocks
    neovim
    nodejs_24
    pnpm
    ripgrep
    sesh
    tealdeer
    tmux
    tmuxPlugins.continuum
    tmuxPlugins.resurrect
    tree-sitter
    turbo
    vhs
    yarn
    # codex installed via homebrew cask
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    NPM_CONFIG_PREFIX = "$HOME/.npm-global";
  };

  home.sessionPath = [
    "$HOME/.npm-global/bin"
    "$HOME/.local/bin"
    "/Applications/Obsidian.app/Contents/MacOS"
  ];

  home.shellAliases = {
    rebuild = "sudo darwin-rebuild switch --flake ~/nix-config#$(hostname -s) && source ~/.zshrc && tmux source-file ~/.tmux.conf 2>/dev/null; true";

    g = "git";
    ga = "git add .";
    gb = "git branch";
    gc = "git commit";
    gca = "git commit --amend";
    gco = "git checkout";
    gcom = "git checkout main --ignore-other-worktrees";
    gf = "git fetch --prune";
    gl = "git log --pretty=format:'%C(yellow)%h%C(reset)%C(red)%d%C(reset)%n%C(cyan)%ar%C(reset) %C(green)<%an>%C(reset)%n%s%n' --no-merges --max-count 5";
    gp = "git pull";
    gpush = "git push";
    gr = "git rebase";
    grom = "git rebase origin/main";
    gs = "git status -s";
    undo = "git reset HEAD~1";
    wip = "git add . && git commit -m 'WIP'";

    docker-start = "colima start";
    docker-stop = "colima stop";

    c = "claude --dangerously-skip-permissions";
    cx = "codex --dangerously-bypass-approvals-and-sandbox";
  };

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
      init.defaultBranch = "main";
      credential.helper = "!gh auth git-credential";
    };
  };

  home.file.".local/bin/tmux-fmt-dir" = {
    executable = true;
    source = ./scripts/tmux-fmt-dir;
  };

  home.file.".local/bin/tmux-fmt-cmd" = {
    executable = true;
    source = ./scripts/tmux-fmt-cmd;
  };

  home.file.".local/bin/tmux-cmd" = {
    executable = true;
    source = ./scripts/tmux-cmd;
  };

  home.file.".local/bin/tmux-detach-window" = {
    executable = true;
    source = ./scripts/tmux-detach-window;
  };

  home.file.".local/bin/sesh-picker-list" = {
    executable = true;
    source = ./scripts/sesh-picker-list;
  };

  home.file.".local/bin/sesh-picker" = {
    executable = true;
    source = ./scripts/sesh-picker;
  };

  home.file.".local/bin/gcert" = {
    executable = true;
    source = ./scripts/gcert;
  };

  home.file.".local/bin/standup" = {
    executable = true;
    source = ./scripts/standup;
  };

  home.file.".local/bin/gitloc" = {
    executable = true;
    source = ./scripts/gitloc;
  };

  home.activation.installGitHooks = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    hooks_dir="$HOME/nix-config/.git/hooks"
    hook_src="$HOME/nix-config/hooks/pre-push"
    hook_dst="$hooks_dir/pre-push"
    if [ -d "$hooks_dir" ] && [ ! "$hook_dst" -ef "$hook_src" ]; then
      ln -sf "$hook_src" "$hook_dst"
    fi
  '';

  home.file.".hushlogin".text = "";

  home.file.".config/tealdeer/config.toml".text = ''
    [updates]
    auto_update = true
  '';

  home.file.".config/kanata/kanata.kbd".source = ./config/kanata/kanata.kbd;
  home.file.".config/ghostty/config".source = ./config/ghostty/config;
  home.file.".config/nvim".source =
    config.lib.file.mkOutOfStoreSymlink "/Users/stevedv/nix-config/config/nvim";

  home.file.".tmux.conf".text = ''
    # Fix PATH for Nix (so run-shell plugins can find tmux, bash, etc.)
    set-environment -g PATH "/etc/profiles/per-user/stevedv/bin:/run/current-system/sw/bin:/usr/bin:/bin:/usr/sbin:/sbin"

    # Status bar at the top, inherits terminal background
    set -g status-position top
    set -g status-style 'bg=default'
    set -g status-left ' '
    set -g status-right '#(cat /tmp/tmux-cmd-state 2>/dev/null) '
    set -g status-right-length 80

    # Vi keys in copy mode (hjkl, /, v, etc.)
    set -g mode-keys vi

    # Mouse support (scrollback, pane selection, select-to-copy)
    set -g mouse on
    bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "pbcopy"

    # Windows start at 1
    set -g base-index 1
    set -g pane-base-index 1
    set -g renumber-windows on

    # Window titles: dir:process
    # Known dirs get short aliases, otherwise show basename
    # Claude Code overwrites its process title with a version — detect and fix
    # When Claude/Codex is awaiting input, hooks set @claude_waiting on the pane → shows orange !!
    set -g automatic-rename on
    set -g allow-rename off
    set -g set-titles off
    set -g window-status-format '#{?#{@claude_waiting},#[fg=colour208],}#I:#(~/.local/bin/tmux-fmt-dir #{pane_current_path}):#(~/.local/bin/tmux-fmt-cmd #{pane_current_command})#{?#{@claude_waiting},!!#[default],}'
    set -g window-status-current-format '#I:#(~/.local/bin/tmux-fmt-dir #{pane_current_path}):#(~/.local/bin/tmux-fmt-cmd #{pane_current_command})'
    set -g window-status-current-style 'bold'
    set -g window-status-style 'dim'
    set-hook -g pane-focus-in 'set-option -p -u @claude_waiting; refresh-client -S'
    set-hook -g window-pane-changed 'set-option -p -u @claude_waiting; refresh-client -S'
    set-hook -g session-window-changed 'set-option -p -u @claude_waiting; refresh-client -S'

    # Hide pane borders
    set -g pane-border-style 'fg=default'
    set -g pane-active-border-style 'fg=default'

    # Dim inactive panes
    set -g window-style 'fg=colour244'
    set -g window-active-style 'fg=default'

    # Extended keys so shift+enter etc. pass through to apps
    set -s extended-keys on
    set -s extended-keys-format csi-u
    set -as terminal-features ',xterm-ghostty:RGB:extkeys'

    # Splits and new windows inherit current directory
    bind-key % split-window -h -c '#{pane_current_path}'
    bind-key '"' split-window -v -c '#{pane_current_path}'
    bind-key c new-window -c '#{pane_current_path}'

    # Clear scrollback buffer (cmd+k via Ghostty)
    bind-key K send-keys C-l \; clear-history

    # Detach window to new Ghostty window (cmd+n via Ghostty)
    bind-key N run-shell "$HOME/.local/bin/tmux-detach-window"

    # Forward shift+enter to apps (CSI u format for Claude Code)
    bind-key -n S-Enter send-keys Escape "[13;2u"

    # Spotlight picker (ctrl+' to toggle)
    # Ghostty intercepts ctrl+' and sends F12. In root table, F12 opens popup.
    # Inside popup, F12 passes through to fzf which aborts on it (--bind f12:abort).
    bind-key -n F12 display-popup -E -w 60% -h 60% "$HOME/.local/bin/sesh-picker"
    # Fallback: direct ctrl+' for opening (works without Ghostty keybind)
    bind-key -n C-\' display-popup -E -w 60% -h 60% "$HOME/.local/bin/sesh-picker"

    # Clear old bindings from previous config
    unbind-key r

    # View live tmux-cmd output (shown as hint after 10s)
    bind-key W new-window -n "task" "tail -f /tmp/tmux-cmd-live"

    # View last tmux-cmd error log
    bind-key R new-window -n "error" "less -R /tmp/tmux-cmd-last-error"

    # Increase scrollback
    set -g history-limit 50000

    # Session persistence (resurrect + continuum)
    run-shell ${pkgs.tmuxPlugins.resurrect}/share/tmux-plugins/resurrect/resurrect.tmux
    run-shell ${pkgs.tmuxPlugins.continuum}/share/tmux-plugins/continuum/continuum.tmux
    set -g @resurrect-capture-pane-contents 'on'
    set -g @continuum-restore 'on'
    set -g @continuum-save-interval '10'
  '';

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;
    completionInit = "autoload -U compinit && compinit -C";
    initContent = lib.mkMerge [
      ''
          # Menu-style tab completion (navigate with arrows)
          zstyle ':completion:*' menu select
          zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

          # Word navigation (Alt+arrows)
          bindkey '\e[1;3D' backward-word
          bindkey '\e[1;3C' forward-word

          # Shadow standard tools with modern alternatives — guard from agents
          if [[ -z "$CLAUDECODE" && -z "$CODEX_SANDBOX" ]]; then
          alias cat="bat"
          alias find="fd"
          alias grep="rg"
          alias ls="eza --icons=always -a"
          alias tree="eza -T -L 4 -a --git-ignore --color=always"
        fi

        gd() { git status -s && echo && git diff "$@"; }

        z() {
          __zoxide_doctor
          if [[ "$#" -eq 0 ]]; then
            __zoxide_cd ~
          elif [[ "$#" -eq 1 ]] && { [[ -d "$1" ]] || [[ "$1" = '-' ]] || [[ "$1" =~ ^[-+][0-9]+$ ]]; }; then
            __zoxide_cd "$1"
          elif [[ "$#" -eq 2 ]] && [[ "$1" = "--" ]]; then
            __zoxide_cd "$2"
          else
            local current result
            current="$(__zoxide_pwd)"
            result="$(command zoxide query --exclude "$current" -- "$@" 2>/dev/null)" && {
              __zoxide_cd "$result"
              return
            }

            # No-op success when already in zoxide's only match.
            result="$(command zoxide query -- "$@" 2>/dev/null)" && {
              if [[ "$result" == "$current" ]]; then
                return 0
              fi
              __zoxide_cd "$result"
              return $?
            }

            command zoxide query --exclude "$current" -- "$@" >/dev/null
            return $?
          fi
        }
      ''
      (lib.mkOrder 950 ''
        # Rebind fzf cd widget from Alt+C to Ctrl+F (after fzf at 910)
        bindkey -r '\ec'
        if zle -la | grep -q fzf-cd-widget; then
          bindkey '^F' fzf-cd-widget
        fi
      '')
    ];
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      format = "$directory$git_branch$git_status\${env_var.CLAUDE_CONTEXT}\${env_var.CLAUDE_SESSION}$character";
      right_format = "$cmd_duration";

      character = {
        success_symbol = "[›](green)";
        error_symbol = "[›](red)";
      };

      directory = {
        truncation_length = 3;
        truncate_to_repo = true;
        style = "blue";
      };

      git_branch = {
        format = "[$branch]($style) ";
        style = "purple";
      };

      git_status = {
        format = "([$all_status$ahead_behind]($style) )";
        style = "yellow";
        ahead = "⇡\${count}";
        behind = "⇣\${count}";
        diverged = "⇡\${ahead_count}⇣\${behind_count}";
      };

      cmd_duration = {
        min_time = 2000;
        format = "[$duration]($style)";
        style = "dimmed white";
      };

      env_var = {
        CLAUDE_CONTEXT = {
          variable = "CLAUDE_CONTEXT";
          format = "[$env_value]($style) ";
          style = "yellow";
        };

        CLAUDE_SESSION = {
          variable = "CLAUDE_SESSION";
          format = "[$env_value]($style)";
          style = "purple";
        };
      };
    };
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultOptions = [
      "--height=40%"
      "--reverse"
    ];
    # Ctrl+F: use fd, skip caches and macOS cruft
    changeDirWidgetCommand = "fd --type d --exclude node_modules --exclude .next --exclude Library";
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
    };
  };

  programs.gpg = {
    enable = true;
    settings = {
      pinentry-mode = "loopback";
    };
  };

  home.file.".gnupg/gpg-agent.conf".text = ''
    allow-loopback-pinentry
    allow-preset-passphrase
  '';
}
