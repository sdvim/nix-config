{ config, pkgs, ... }: {
  home.username = "stevedv";
  home.homeDirectory = "/Users/stevedv";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    bat
    eza
    fd
    ripgrep
    fzf
    jq
    tealdeer
    neovim
    nodejs_24
    yarn
    turbo
    eas-cli
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
    vhs

    kanata

    # TODO: uncomment after uninstalling brew claude-code
    # claude-code
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  home.sessionPath = [
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
    gcom = "git checkout main";
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
    cx = "codex --full-auto";
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

      start_time=$(date +%s)

      # Spinner loop in background — after 10s, append hotkey hint
      spinner_frames=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)
      (
        while true; do
          elapsed=$(( $(date +%s) - start_time ))
          hint=""
          if (( elapsed >= 10 )); then
            hint=" #[dim]prefix+W#[default]"
          fi
          for f in "''${spinner_frames[@]}"; do
            printf "%s %s%s" "$label" "$f" "$hint" > "$STATEFILE"
            tmux refresh-client -S
            sleep 0.3
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
        printf "#[fg=red]%s FAILED#[default] #[dim]prefix+R#[default]" "$ok_label" > "$STATEFILE"
        ln -sf "$LOGFILE" /tmp/tmux-cmd-last-error
      fi
      tmux refresh-client -S

      sleep 5
      : > "$STATEFILE"
      tmux refresh-client -S
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
    set -g automatic-rename on
    set -g allow-rename off
    set -g set-titles off
    set -g window-status-format '#I:#{?#{m:*/nix-config,#{pane_current_path}},nix,#{?#{m:*/courtyard-frontend*,#{pane_current_path}},cyfe,#{b:pane_current_path}}}:#{?#{m:[0-9]*,#{pane_current_command}},✱,#{?#{m:codex*,#{pane_current_command}},¢,#{pane_current_command}}}'
    set -g window-status-current-format '#I:#{?#{m:*/nix-config,#{pane_current_path}},nix,#{?#{m:*/courtyard-frontend*,#{pane_current_path}},cyfe,#{b:pane_current_path}}}:#{?#{m:[0-9]*,#{pane_current_command}},✱,#{?#{m:codex*,#{pane_current_command}},¢,#{pane_current_command}}}'
    set -g window-status-current-style 'bold'
    set -g window-status-style 'dim'

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

    # New session (cmd+n via Ghostty)
    bind-key N new-session -c '#{pane_current_path}'

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

  home.file.".claude/statusline.sh" = {
    executable = true;
    text = ''
      #!/bin/bash
      input=$(cat)

      export CLAUDE_MODEL=$(echo "$input" | jq -r '.model.display_name // "?"')
      export CLAUDE_CONTEXT=$(printf '%s%%' "$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)")

      session_name=$(echo "$input" | jq -r '.session_name // empty')
      [[ -n "$session_name" ]] && export CLAUDE_SESSION="$session_name"

      STARSHIP_SHELL= starship prompt
    '';
  };

  # Runtime overrides go in ~/.claude/settings.local.json
  home.file.".claude/settings.json".text = builtins.toJSON {
    skipDangerousModePermissionPrompt = true;
    statusLine = {
      type = "command";
      command = "/Users/stevedv/.claude/statusline.sh";
    };
  };

  programs.zsh = {
    enable = true;
    initContent = ''
      # Shadow standard tools with modern alternatives — guard from agents
      if [[ -z "$CLAUDECODE" && -z "$CODEX_SANDBOX" ]]; then
        alias cat="bat"
        alias find="fd"
        alias grep="rg"
        alias ls="eza --icons=always -a"
        alias tree="eza -T -L 4 -a --git-ignore --color=always"
      fi

      gd() { git status -s && echo && git diff "$@"; }
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
