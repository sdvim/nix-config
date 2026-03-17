{ pkgs, userName, ... }:
{
  homebrew.brews = [
    "cocoapods"
  ];

  homebrew.casks = [
    "android-studio"
  ];

  home-manager.users.${userName} =
    { config, lib, ... }:
    {
      home.packages = with pkgs; [
        eas-cli
        mise
      ];

      home.file.".local/bin/work-mcp" = {
        executable = true;
        source = pkgs.writeShellScript "work-mcp" ''
          set -euo pipefail

          LINEAR_URL="https://mcp.linear.app/mcp"
          SLACK_URL="https://mcp.slack.com/mcp"
          SLACK_CLIENT_ID="1601185624273.8899143856786"
          SLACK_CALLBACK_PORT=3118

          log() {
            printf '[work-mcp] %s\n' "$*"
          }

          warn() {
            printf '[work-mcp] %s\n' "$*" >&2
          }

          ensure_claude_config() {
            local config tmp
            config="$HOME/.claude.json"

            if ! command -v jq >/dev/null 2>&1; then
              warn "jq is not installed; skipping Claude MCP reconciliation"
              return 0
            fi

            if [ -f "$config" ] && ! jq empty "$config" >/dev/null 2>&1; then
              warn "$config is invalid JSON; skipping Claude MCP reconciliation"
              return 0
            fi

            tmp=$(mktemp)
            if [ -f "$config" ]; then
              jq \
                --arg linear_url "$LINEAR_URL" \
                --arg slack_url "$SLACK_URL" \
                --arg slack_client_id "$SLACK_CLIENT_ID" \
                --argjson slack_callback_port "$SLACK_CALLBACK_PORT" \
                '
                  .mcpServers = (.mcpServers // {})
                  | .mcpServers.linear = {
                    type: "http",
                    url: $linear_url
                  }
                  | .mcpServers.slack = {
                    type: "http",
                    url: $slack_url,
                    oauth: {
                      clientId: $slack_client_id,
                      callbackPort: $slack_callback_port
                    }
                  }
                ' \
                "$config" > "$tmp"
            else
              jq \
                --null-input \
                --arg linear_url "$LINEAR_URL" \
                --arg slack_url "$SLACK_URL" \
                --arg slack_client_id "$SLACK_CLIENT_ID" \
                --argjson slack_callback_port "$SLACK_CALLBACK_PORT" \
                '
                  {
                    mcpServers: {
                      linear: {
                        type: "http",
                        url: $linear_url
                      },
                      slack: {
                        type: "http",
                        url: $slack_url,
                        oauth: {
                          clientId: $slack_client_id,
                          callbackPort: $slack_callback_port
                        }
                      }
                    }
                  }
                ' > "$tmp"
            fi

            mv "$tmp" "$config"
          }

          ensure_codex_features() {
            local config tmp
            config="$1"
            tmp=$(mktemp)

            awk '
              BEGIN {
                in_features = 0
                saw_features = 0
                inserted = 0
              }

              /^\[features\]$/ {
                saw_features = 1
                in_features = 1
                inserted = 0
                print
                next
              }

              /^\[/ {
                if (in_features && !inserted) {
                  print "rmcp_client = true"
                  inserted = 1
                }
                in_features = 0
                print
                next
              }

              {
                if (in_features && $0 ~ /^[[:space:]]*rmcp_client[[:space:]]*=/) {
                  if (!inserted) {
                    print "rmcp_client = true"
                    inserted = 1
                  }
                  next
                }

                print
              }

              END {
                if (in_features && !inserted) {
                  print "rmcp_client = true"
                }

                if (!saw_features) {
                  print ""
                  print "[features]"
                  print "rmcp_client = true"
                }
              }
            ' "$config" > "$tmp"

            mv "$tmp" "$config"
          }

          remove_toml_table() {
            local config section tmp
            config="$1"
            section="$2"
            tmp=$(mktemp)

            awk -v header="[''${section}]" '
              $0 == header {
                skip = 1
                next
              }

              /^\[/ {
                if (skip) {
                  skip = 0
                }
              }

              !skip {
                print
              }
            ' "$config" > "$tmp"

            mv "$tmp" "$config"
          }

          ensure_codex_config() {
            local config
            config="$HOME/.codex/config.toml"
            mkdir -p "$(dirname "$config")"
            touch "$config"

            ensure_codex_features "$config"
            remove_toml_table "$config" "mcp_servers.linear"

            printf '\n[mcp_servers.linear]\nurl = "%s"\n' "$LINEAR_URL" >> "$config"
          }

          ensure_all() {
            ensure_claude_config
            ensure_codex_config
            log "ensured Claude and Codex MCP configuration for work hosts"
          }

          login_codex_linear() {
            ensure_all

            if ! command -v codex >/dev/null 2>&1; then
              warn "codex is not installed"
              return 1
            fi

            log "starting Codex Linear OAuth"
            codex mcp login linear
            log "Claude will prompt for Linear and Slack OAuth the first time those tools are used"
          }

          status_all() {
            printf 'Claude MCPs:\n'
            if command -v claude >/dev/null 2>&1; then
              claude mcp list || true
            else
              printf 'claude not installed\n'
            fi

            printf '\nCodex MCPs:\n'
            if command -v codex >/dev/null 2>&1; then
              codex mcp list || true
            else
              printf 'codex not installed\n'
            fi
          }

          case "''${1:-ensure}" in
            ensure)
              ensure_all
              ;;
            login)
              login_codex_linear
              ;;
            status)
              status_all
              ;;
            *)
              printf 'usage: %s [ensure|login|status]\n' "$0" >&2
              exit 1
              ;;
          esac
        '';
      };

      home.activation.ensureWorkMcp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        PATH="/etc/profiles/per-user/${userName}/bin:/run/current-system/sw/bin:/usr/bin:/bin:/usr/sbin:/sbin" \
          "${config.home.file.".local/bin/work-mcp".source}" ensure
      '';
    };
}
