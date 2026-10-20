# dotfiles

My macOS and Linux config, managed with [chezmoi](https://www.chezmoi.io/).

| Target | Source | Managed |
|---|---|---|
| `~/.config/tmux/tmux.conf` | `dot_config/tmux/tmux.conf` | whole file |
| `~/.config/ccstatusline/settings.json` | `dot_config/ccstatusline/settings.json` | whole file |
| `~/.claude/settings.json` | `.chezmoitemplates/claude/` | only the keys listed there |
| `~/.codex/config.toml` | `.chezmoitemplates/codex/` | only the keys listed there |

## Install

```sh
mise use -g chezmoi
chezmoi init --apply vcth4nh
```

Without mise: `sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin init --apply vcth4nh`

`chezmoi init` asks which [profile](#profiles) this machine gets for Claude Code and for Codex. To skip the questions, add `--promptChoice "Claude Code profile=bypass" --promptChoice "Codex profile=bypass"` (or `=hardened`). To switch later, run `chezmoi init --prompt` (the current answers are the defaults), then `chezmoi apply`.

tmux.conf is tested on tmux 3.4 (Ubuntu 24.04), 3.5a (Debian 13) and 3.6a (macOS).

## Profiles

The hardened profiles keep an agent from breaking something by accident; they aren't meant to stop an attacker. Each app has a shared `base` file plus one file per profile, added on top.

Claude Code:

- **hardened** (the default): sessions start in auto mode and shell commands run in the sandbox. A command that has to leave the sandbox goes through auto mode's checks like any other action. On Linux the sandbox needs `bubblewrap` and `socat` (`sudo apt-get install bubblewrap socat`), plus an AppArmor profile for `bwrap` on Ubuntu 24.04 and later ([steps](https://code.claude.com/docs/en/sandboxing#set-up-linux-and-wsl2)). Without them, commands run outside the sandbox, still checked by auto mode.
- **bypass**: sessions start in bypassPermissions mode, without the confirmation dialog, and the sandbox is off. Claude Code refuses this mode when it runs as root or under sudo.

Codex:

- **hardened** (the default): commands run in the `workspace-write` sandbox with no network access. When a command needs more, a reviewer model checks it instead of asking you (`approvals_reviewer = "auto_review"`). If the reviewer refuses, Codex looks for a safer way or asks you.
- **bypass**: no sandbox (`danger-full-access`) and no approval prompts (`approval_policy = "never"`).

## Claude Code and Codex settings

Both apps keep machine-local state in the same file as their settings: Codex its per-project trust list, Claude its hooks and auto-mode environment. So this repo owns only the keys listed in `.chezmoitemplates/`: for each app, the base file plus the machine's profile file. `dot_claude/modify_settings.json` and `dot_codex/modify_private_config.toml` merge them into the live files and keep everything else.

- A key that holds an object (`env`, `permissions`, `sandbox`, `enabledPlugins`, a TOML table) is merged one level deep: the repo sets the entries it lists, and the machine keeps its other entries. Lists and single values are replaced.
- Nothing is ever removed. An entry deleted from the repo, or set only by the profile a machine switched away from, stays on that machine until you delete it there.
- When the owned entries already match, the file is left byte-for-byte as it is. When one differs, the file is rewritten with its keys sorted.
- To change an owned entry, edit it in `.chezmoitemplates/` and run `chezmoi apply`. A change to it made from inside Claude or Codex is reverted at the next apply, and `chezmoi re-add` doesn't work on these two files.

## Day to day

- `chezmoi diff` shows what `chezmoi apply` would change.
- `chezmoi re-add` copies tmux.conf or the ccstatusline settings back into the repo after you change them in place (ccstatusline's TUI rewrites its file).
- `chezmoi update` pulls and applies on the other machines.
