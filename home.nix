{
  config,
  pkgs,
  lib,
  flakeDir,
  userName,
  ...
}:
let
  terminalWorkspace = "~";
  renderTemplate =
    path:
    builtins.replaceStrings [ "__TERMINAL_WORKSPACE__" ] [ terminalWorkspace ] (builtins.readFile path);
in
{
  imports = [ ./claude.nix ];

  home.username = userName;
  home.homeDirectory = "/Users/${userName}";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    _1password-cli
    ast-grep
    bat
    biome

    bun
    eza
    fd
    # fzf installed via programs.fzf below
    gh
    git-crypt
    gnupg
    pinentry_mac
    jq
    # kanata
    lazygit
    lua5_1
    luarocks
    mermaid-cli
    neovim
    nodePackages.neovim
    nodejs_24
    pnpm
    ripgrep
    tealdeer
    tmux
    tmuxPlugins.continuum
    tmuxPlugins.resurrect
    tree-sitter
    turbo
    vhs
    wget
    yarn
    zsh-completions
    # codex installed via homebrew cask
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    NPM_CONFIG_PREFIX = "$HOME/.npm-global";
    LANG = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
  };

  home.sessionPath = [
    "$HOME/.npm-global/bin"
    "$HOME/.local/bin"
    "/Applications/Obsidian.app/Contents/MacOS"
  ];

  home.shellAliases = {
    rebuild = "sudo darwin-rebuild switch --flake ${flakeDir}#$(hostname -s) && source ~/.zshrc && tmux source-file ~/.tmux.conf 2>/dev/null; aerospace reload-config 2>/dev/null; ghostty +reload-config 2>/dev/null; true";
    reload = "source ~/.zshrc";

    g = "git";
    ga = "git add .";
    gb = "git branch";
    gc = "git commit";
    gca = "git commit --amend";
    gco = "git checkout";
    gcom = "git checkout main --ignore-other-worktrees";
    gf = "git fetch --prune";
    gl = "git log --pretty=format:'%C(yellow)%h%C(reset)%C(red)%d%C(reset)%n%C(cyan)%ar%C(reset) %C(green)<%an>%C(reset)%n%s%n' --no-merges --max-count 5";
    gpom = "git pull origin main";
    gp = "git push";
    gr = "git rebase";
    grom = "git rebase origin/main";
    gs = "git status -s";
    undo = "git reset HEAD~1";
    wip = "git add . && git commit -m 'WIP'";
    rwt = "suffix=$(basename \"$(pwd)\" | sed 's/.*-//') && git checkout \"main-$suffix\" && git pull origin main && git fetch --prune";

    c = "claude --allow-dangerously-skip-permissions --permission-mode plan";
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

  home.file.".local/bin/tmux-claude-indicator" = {
    executable = true;
    source = ./scripts/tmux-claude-indicator;
  };

  home.file.".local/bin/tmux-claude-next" = {
    executable = true;
    source = ./scripts/tmux-claude-next;
  };

  home.file.".local/bin/tmux-move-pane-prev-session" = {
    executable = true;
    source = pkgs.writeShellScript "tmux-move-pane-prev-session" ''
      set -euo pipefail

      tmux_bin=/etc/profiles/per-user/${userName}/bin/tmux
      current_session="''${1:-}"
      pane_id="''${2:-}"
      current_client_tty="''${3:-}"
      current_window_id="''${4:-}"

      if [ -z "$current_session" ] || [ -z "$pane_id" ] || [ -z "$current_client_tty" ] || [ -z "$current_window_id" ]; then
        "$tmux_bin" display-message "Missing tmux pane/session context"
        exit 1
      fi

      session_index() {
        case "$1" in
          main)
            echo 0
            ;;
          main-*)
            local suffix="''${1#main-}"
            if [[ "$suffix" =~ ^[0-9]+$ ]]; then
              echo "$suffix"
            else
              echo -1
            fi
            ;;
          *)
            echo -1
            ;;
        esac
      }

      current_index="$(session_index "$current_session")"
      target_session=""
      best_index=-1

      while IFS= read -r session_name; do
        idx="$(session_index "$session_name")"
        if [ "$idx" -ge 0 ] && [ "$idx" -lt "$current_index" ] && [ "$idx" -gt "$best_index" ]; then
          best_index="$idx"
          target_session="$session_name"
        fi
      done < <("$tmux_bin" list-sessions -F '#{session_name}')

      if [ -z "$target_session" ]; then
        "$tmux_bin" display-message "No previous tmux session"
        exit 0
      fi

      target_client_tty="$(
        "$tmux_bin" list-clients -F '#{client_tty}	#{session_name}' \
          | awk -F '	' -v current_tty="$current_client_tty" -v target="$target_session" '
              $1 != current_tty && $2 == target {
                print $1
                exit
              }
            '
      )"

      if [ -n "$target_client_tty" ]; then
        "$tmux_bin" switch-client -c "$target_client_tty" -t "$current_session"
      fi

      target_window_id="$("$tmux_bin" display-message -p -t "$target_session" '#{window_id}')"

      "$tmux_bin" move-pane -s "$pane_id" -t "$target_session"
      "$tmux_bin" select-layout -t "$target_window_id" even-horizontal >/dev/null 2>&1 || true
      "$tmux_bin" select-layout -t "$current_window_id" even-horizontal >/dev/null 2>&1 || true
      "$tmux_bin" switch-client -t "$target_session"
    '';
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

  home.file.".local/bin/tmux-session" = {
    executable = true;
    source = ./scripts/tmux-session;
  };

  home.file.".local/bin/tmux-new-session" = {
    executable = true;
    source = ./scripts/tmux-new-session;
  };

  home.file.".local/bin/worktree-scaffold" = {
    executable = true;
    source = ./scripts/worktree-scaffold;
  };

  home.file.".local/bin/keybindings-help" = {
    executable = true;
    source = ./scripts/keybindings-help;
  };

  home.file.".local/bin/tmux-responsive-layout" = {
    executable = true;
    source = ./scripts/tmux-responsive-layout;
  };

  home.file.".local/bin/aerospace-terminal-toggle" = {
    executable = true;
    text = renderTemplate ./scripts/aerospace-terminal-toggle;
  };

  home.file.".local/bin/aerospace-workspace-caps" = {
    executable = true;
    text = renderTemplate ./scripts/aerospace-workspace-caps;
  };

  home.file.".local/bin/ci" = {
    executable = true;
    source = ./scripts/ci;
  };

  home.activation.installGitHooks = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    hooks_dir="${flakeDir}/.git/hooks"
    hook_src="${flakeDir}/hooks/pre-push"
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

  home.file.".config/aerospace/aerospace.toml".text = lib.mkDefault (
    renderTemplate ./config/aerospace/aerospace.toml
  );
  # home.file.".config/kanata/kanata.kbd".source = ./config/kanata/kanata.kbd;
  home.file.".config/ghostty/config".text = lib.mkDefault (builtins.readFile ./config/ghostty/config);
  home.file.".config/nvim".source = config.lib.file.mkOutOfStoreSymlink "${flakeDir}/config/nvim";

  home.file.".tmux.conf".text = ''
    # Fix PATH for Nix (so run-shell plugins can find tmux, bash, etc.)
    set-environment -g PATH "/etc/profiles/per-user/${userName}/bin:/run/current-system/sw/bin:/usr/bin:/bin:/usr/sbin:/sbin"

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
    # Per-pane Claude indicators: ! = waiting, ✱ = active
    set -g automatic-rename on
    set -g allow-rename off
    set -g set-titles off
    set -g window-status-format '#{?@window_has_alerts,#[fg=colour208],}#I:#(~/.local/bin/tmux-fmt-dir #{pane_current_path}):#(~/.local/bin/tmux-fmt-cmd #{pane_current_command} #{window_id})#(~/.local/bin/tmux-claude-indicator #{window_id})#{?@window_has_alerts,#[default],}'
    set -g window-status-current-format '#{?@window_has_alerts,#[fg=colour208 bold],#[bold]}#I:#(~/.local/bin/tmux-fmt-dir #{pane_current_path}):#(~/.local/bin/tmux-fmt-cmd #{pane_current_command} #{window_id})#(~/.local/bin/tmux-claude-indicator #{window_id})#{?@window_has_alerts,#[default],}'
    set -g window-status-current-style 'bold'
    set -g window-status-style 'dim'
    set-hook -g pane-focus-in 'run-shell -b "P=$(tmux display -p \"#{pane_id}\"); tmux set-option -p -u @claude_waiting 2>/dev/null; grep -vxF $P /tmp/tmux-claude-queue > /tmp/tmux-claude-queue.tmp 2>/dev/null && mv /tmp/tmux-claude-queue.tmp /tmp/tmux-claude-queue || rm -f /tmp/tmux-claude-queue.tmp; tmux refresh-client -S"'
    # set-hook -g client-resized 'run-shell -b "$HOME/.local/bin/tmux-responsive-layout"'

    # Dim pane borders
    set -g pane-border-style 'fg=colour238'
    set -g pane-active-border-style 'fg=colour238'

    # Dim inactive panes (subtle foreground dim)
    set -g window-style 'fg=colour251,bg=default'
    set -g window-active-style 'fg=terminal,bg=default'

    # Auto-equalize panes on split/close (skip when zoomed)
    set-hook -g after-split-window "if-shell 'tmux display -p \"#{window_zoomed_flag}\" | grep -q 1' ''' 'select-layout -E'"
    set-hook -g pane-exited "if-shell 'tmux display -p \"#{window_zoomed_flag}\" | grep -q 1' ''' 'select-layout -E'"

    # Extended keys so shift+enter etc. pass through to apps
    set -s extended-keys on
    set -s extended-keys-format csi-u
    set -as terminal-features ',xterm-ghostty:RGB:extkeys'

    # Let apps know when their pane gains/loses focus (hides cursor in inactive panes)
    set -g focus-events on

    # Splits and new windows inherit current directory
    bind-key % split-window -h -c '#{pane_current_path}'
    bind-key '"' split-window -v -c '#{pane_current_path}'
    bind-key c new-window -c '#{pane_current_path}'

    # Select panes by number (prefix + N)
    bind-key 0 select-pane -t :.0
    bind-key 1 select-pane -t :.1
    bind-key 2 select-pane -t :.2
    bind-key 3 select-pane -t :.3
    bind-key 4 select-pane -t :.4
    bind-key 5 select-pane -t :.5
    bind-key 6 select-pane -t :.6
    bind-key 7 select-pane -t :.7
    bind-key 8 select-pane -t :.8
    bind-key 9 select-pane -t :.9

    # Select windows by number (prefix + Alt+N)
    bind-key M-0 select-window -t :0
    bind-key M-1 select-window -t :1
    bind-key M-2 select-window -t :2
    bind-key M-3 select-window -t :3
    bind-key M-4 select-window -t :4
    bind-key M-5 select-window -t :5
    bind-key M-6 select-window -t :6
    bind-key M-7 select-window -t :7
    bind-key M-8 select-window -t :8
    bind-key M-9 select-window -t :9

    # Previous pane (reverse of built-in 'o')
    bind-key O select-pane -t :.-

    # Clear scrollback buffer (cmd+k via Ghostty)
    bind-key K if -F '#{m:[0-9]*,#{pane_current_command}}' {run-shell -b 'P="#{pane_id}"; tmux send-keys -t "$P" -l "/clear"; sleep 0.05; tmux send-keys -t "$P" Enter; sleep 0.5; tmux send-keys -t "$P" -l "/plan"; sleep 0.05; tmux send-keys -t "$P" Enter'} {send-keys C-l ; clear-history}

    # Forward shift+enter to apps (CSI u format for Claude Code)
    bind-key -n S-Enter send-keys Escape "[13;2u"

    # Clear old bindings from previous config
    unbind-key r

    # View live tmux-cmd output (shown as hint after 10s)
    bind-key W new-window -n "task" "tail -f /tmp/tmux-cmd-live"

    # Open GitHub PR for current branch in browser (cmd+r via Ghostty)
    bind-key R run-shell -b "cd '#{pane_current_path}' && gh pr view --web 2>/dev/null || tmux display-message 'No PR found for this branch'"

    # Open PR on devinreview.com (cmd+shift+r via Ghostty)
    bind-key -n M-R run-shell -b "cd '#{pane_current_path}' && url=$(gh pr view --json url -q .url 2>/dev/null | sed 's|github.com|devinreview.com|') && [ -n \"$url\" ] && open \"$url\" || tmux display-message 'No PR found for this branch'"

    # Jump to next waiting Claude pane (prefix + G)
    bind-key G run-shell "$HOME/.local/bin/tmux-claude-next"

    # Move current pane to previous tmux session and follow it
    bind-key M run-shell -b "$HOME/.local/bin/tmux-move-pane-prev-session '#{session_name}' '#{pane_id}' '#{client_tty}' '#{window_id}'"

    # Keybinding cheatsheet (cmd+shift+? via Ghostty)
    bind-key ? display-popup -E -w 80% -h 80% "$HOME/.local/bin/keybindings-help"

    # Responsive layout: manual break/join panes
    bind-key B run-shell -b "$HOME/.local/bin/tmux-responsive-layout break"
    bind-key J run-shell -b "$HOME/.local/bin/tmux-responsive-layout join"

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
          # Suppress partial-line indicator (highlighted %)
          unsetopt PROMPT_SP

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
        export GPG_TTY=$(tty)
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
      format = "$directory$git_branch$git_status\${env_var.CLAUDE_CONTEXT}\${env_var.CI_STATUS}$character";
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

        CI_STATUS = {
          variable = "CI_STATUS";
          format = "$env_value ";
          style = "";
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
  };

  home.file.".gnupg/gpg-agent.conf".text = ''
    pinentry-program ${pkgs.pinentry_mac}/Applications/pinentry-mac.app/Contents/MacOS/pinentry-mac
    default-cache-ttl 34560000
    max-cache-ttl 34560000
  '';

}
