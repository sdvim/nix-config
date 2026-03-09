{ config, pkgs, ... }:
{
  imports = [ ./claude.nix ];

  home.username = "stevedv";
  home.homeDirectory = "/Users/stevedv";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    bat
    eza
    fd
    ripgrep
    # fzf installed via programs.fzf below
    jq
    tealdeer
    neovim
    nodejs_24
    pnpm
    yarn
    turbo
    eas-cli
    biome
    ast-grep
    tree-sitter
    lazygit
    lua5_1
    luarocks
    bun
    sesh
    tmux
    tmuxPlugins.resurrect
    tmuxPlugins.continuum
    gh
    gnupg
    git-crypt
    # codex installed via homebrew cask
    bitwarden-cli
    _1password-cli
    vhs

    kanata
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
    rebuild = "sudo darwin-rebuild switch --flake ~/nix-config#air && source ~/.zshrc && tmux source-file ~/.tmux.conf 2>/dev/null; true";

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
    };
  };

  home.file.".local/bin/tmux-fmt-dir" = {
    executable = true;
    text = ''
      #!/bin/bash
      case "$1" in
        */nix-config)          echo "nix" ;;
        */courtyard-frontend*) echo "cyfe" ;;
        /Users/stevedv)        echo "~" ;;
        *)                     basename "$1" ;;
      esac
    '';
  };

  home.file.".local/bin/tmux-fmt-cmd" = {
    executable = true;
    text = ''
      #!/bin/bash
      case "$1" in
        [0-9]*)  echo "✱" ;;
        codex*)  echo "¢" ;;
        gemini*) echo "✦" ;;
        *)       echo "$1" ;;
      esac
    '';
  };

  home.file.".local/bin/tmux-cmd" = {
    executable = true;
    text = ''
      #!/bin/bash
      # Usage: tmux-cmd <label> <command...>
      # Example: tmux-cmd "rebuilding" sudo darwin-rebuild switch --flake ~/nix-config#air
      label="$1"; shift
      STATEFILE="/tmp/tmux-cmd-state"
      LOGFILE=$(mktemp /tmp/tmux-cmd-XXXXXX)
      ln -sf "$LOGFILE" /tmp/tmux-cmd-live

      # Spinner loop in background — show hotkey hint before label
      spinner_frames=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)
      (
        while true; do
          for f in "''${spinner_frames[@]}"; do
            printf "#[dim][^b w]#[default] %s %s" "$label" "$f" > "$STATEFILE"
            tmux refresh-client -S
            sleep 0.12
          done
        done
      ) &
      spinner_pid=$!

      # Run the actual command, capture output
      if "$@" >"$LOGFILE" 2>&1; then
        kill $spinner_pid 2>/dev/null
        ok_label="''${label%ing}"
        printf "#[fg=green]%s OK#[default]" "$ok_label" > "$STATEFILE"
      else
        kill $spinner_pid 2>/dev/null
        ok_label="''${label%ing}"
        printf "#[dim][^b R]#[default] #[fg=red]%s FAILED#[default]" "$ok_label" > "$STATEFILE"
        ln -sf "$LOGFILE" /tmp/tmux-cmd-last-error
      fi
      tmux refresh-client -S

      sleep 5
      : > "$STATEFILE"
      tmux refresh-client -S
    '';
  };

  home.file.".local/bin/tmux-detach-window" = {
    executable = true;
    text = ''
      #!/bin/bash
      set -euo pipefail

      current_session="$(tmux display-message -p '#{session_name}')"
      current_window="$(tmux display-message -p '#{window_id}')"
      window_count="$(tmux display-message -p '#{session_windows}')"

      # Don't detach the last window — would destroy the session
      if [ "$window_count" -le 1 ]; then
        tmux display-message "Cannot detach: only one window in session"
        exit 0
      fi

      # Find next available session name: main-2, main-3, ...
      n=2
      while tmux has-session -t "''${current_session}-''${n}" 2>/dev/null; do
        n=$((n + 1))
      done
      new_session="''${current_session}-''${n}"

      # Create detached session (comes with a throwaway window)
      tmux new-session -d -s "$new_session"

      # Move current window to the new session
      tmux move-window -s "$current_window" -t "''${new_session}:"

      # Kill the throwaway window
      for wid in $(tmux list-windows -t "$new_session" -F '#{window_id}'); do
        if [ "$wid" != "$current_window" ]; then
          tmux kill-window -t "$wid"
        fi
      done

      # Renumber windows in both sessions
      tmux move-window -r -t "$new_session"
      tmux move-window -r -t "$current_session"

      # Launch new Ghostty window attached to the new session
      open -n -a Ghostty.app --args \
        --quit-after-last-window-closed \
        --fullscreen=true \
        -e /etc/profiles/per-user/stevedv/bin/tmux attach-session -t "$new_session"
    '';
  };

  home.file.".local/bin/sesh-picker-list" = {
    executable = true;
    text = ''
      #!/bin/bash
      # Generate spotlight picker entries
      echo "$ rebuild"
      echo "$ push"
      sesh list | while read -r s; do echo "◆ $s"; done
      fd --type f --max-depth 4 --exclude .git -c never 2>/dev/null | head -20 | while read -r f; do echo "… $f"; done
    '';
  };

  home.file.".local/bin/sesh-picker" = {
    executable = true;
    text = ''
      #!/bin/bash
      CACHE="/tmp/sesh-picker-cache"

      # Serve cache if fresh (<10m), refresh with ctrl+r
      if [[ -f "$CACHE" ]] && (( $(date +%s) - $(stat -f %m "$CACHE") < 600 )); then
        list=$(cat "$CACHE")
      else
        list=$("$HOME/.local/bin/sesh-picker-list")
        echo "$list" > "$CACHE"
      fi

      choice=$(echo "$list" | fzf --height 100% --no-sort --ansi \
          --history "$HOME/.sesh_picker_history" \
          --bind "ctrl-c:abort,f12:abort" \
          --bind "ctrl-r:reload($HOME/.local/bin/sesh-picker-list)")

      [[ -z "$choice" ]] && exit 0

      type="''${choice%% *}"
      value="''${choice#* }"

      case "$type" in
        '$')
          case "$value" in
            rebuild) tmux run-shell -b "$HOME/.local/bin/tmux-cmd rebuilding sudo darwin-rebuild switch --flake ~/nix-config#air" ;;
            push)    tmux run-shell -b "$HOME/.local/bin/tmux-cmd pushing git push" ;;
          esac
          ;;
        ◆)
          dir="''${value/#\~/$HOME}"
          name=$(basename "$dir")
          # Switch to existing session, or create one in the directory
          if tmux has-session -t "=$name" 2>/dev/null; then
            tmux switch-client -t "=$name"
          else
            tmux new-session -d -s "$name" -c "$dir"
            tmux switch-client -t "=$name"
          fi
          ;;
        …) tmux new-window -c '#{pane_current_path}' "''${EDITOR:-nvim} '$value'" ;;
      esac
    '';
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

    # Status bar: black background, at the top
    set -g status-position top
    set -g status-style 'bg=black'
    set -g status-left ' '
    set -g status-right '#(cat /tmp/tmux-cmd-state 2>/dev/null) '
    set -g status-right-length 80

    # Vi keys in copy mode (hjkl, /, v, etc.)
    set -g mode-keys vi

    # Mouse support (scrollback, pane selection)
    set -g mouse on

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
    set -g pane-border-style 'fg=black'
    set -g pane-active-border-style 'fg=black'

    # Dim inactive panes (muted text + raised background)
    set -g window-style 'fg=#555555,bg=#111111'
    set -g window-active-style 'fg=#ffffff,bg=#000000'

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
    initContent = ''
      # Menu-style tab completion (navigate with arrows)
      zstyle ':completion:*' menu select
      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

      # Word navigation (Alt+arrows)
      bindkey '\e[1;3D' backward-word
      bindkey '\e[1;3C' forward-word

      # Rebind fzf cd widget from Alt+C to Ctrl+F
      bindkey -r '\ec'
      bindkey '^F' fzf-cd-widget

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
    '';
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      format = "$directory$git_branch$git_status\${env_var.CLAUDE_MODEL}\${env_var.CLAUDE_CONTEXT}\${env_var.CLAUDE_SESSION}$character";
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
        CLAUDE_MODEL = {
          variable = "CLAUDE_MODEL";
          format = "[\\[$env_value\\]]($style) ";
          style = "bold cyan";
        };

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
}
