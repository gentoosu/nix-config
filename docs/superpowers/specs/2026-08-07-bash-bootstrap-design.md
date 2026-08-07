# Bash Bootstrap Script — Design

**Date:** 2026-08-07
**Goal:** Replicate the functionality of this nix-darwin + home-manager configuration in a single, portable bash script that bootstraps any Mac without Nix.

## Decisions

- **Standalone, portable:** No Nix required. Homebrew is the package source. Parameterized (username, git identity) so it works on any machine.
- **One-time bootstrap:** Assumes a fresh-ish Mac. Not designed for repeated convergence runs.
- **Dotfiles:** Backup existing files to `<file>.bak` once, then overwrite with the managed version.
- **Structure:** Single file `bootstrap.sh` with a clearly-marked configuration section at the top (mirroring `config.nix`), followed by install logic in phases.

## Configuration section

Variables at the top of the script, editable before running:

- `USERNAME` — defaults to `$(whoami)`
- `GIT_NAME` — default "Mike Hershberger"
- `GIT_EMAIL` — default "mike.hershberger@gmail.com"
- `FORMULAE=(...)` — brew formulae list
- `CASKS=(...)` — brew casks list
- `DOCK_APPS=(...)` — dock apps in order
- macOS preference variables: `INITIAL_KEY_REPEAT=15`, `KEY_REPEAT=2`, `DOCK_TILESIZE=24`, `DOCK_LARGESIZE=32`, `ALACRITTY_FONT_SIZE=14`, etc.

## Phase 1 — Homebrew

Install Homebrew if `brew` is not on PATH (official install script, `NONINTERACTIVE=1`). Handle the Apple Silicon prefix (`/opt/homebrew/bin`) by eval-ing `brew shellenv` for the current run.

## Phase 2 — Packages

Nix package → Homebrew mapping:

| Nix package | Homebrew |
|---|---|
| ansible, awscli2→awscli, cloudflared, curl, docker, dos2unix, git, htop, iftop, iperf3, jq, postgresql, nmap, ripgrep, tree, uv, watch, yq | same-named formulae |
| kubernetes-helm | `helm` |
| kubectl | `kubernetes-cli` |
| kubectx, kustomize, terragrunt, localstack | same-named formulae |
| google-cloud-sdk | cask `google-cloud-sdk` |
| terraform | `hashicorp/tap/terraform` (core formula frozen at 1.5.7) |
| terraform-local | `uv tool install terraform-local` |
| meslo-lgs-nf | cask `font-meslo-lg-nerd-font` |
| powerline (font) | covered by nerd font casks |
| spotify, slack, google-chrome, rectangle | same-named casks |
| brave (chromium package) | cask `brave-browser` |
| pwnvim | **not replicable** (Nix flake); install `neovim` formula and note it |

Also installed to support the config: `fzf`, `bat`, `coreutils`, `dockutil`, `zsh-autosuggestions`, `zsh-syntax-highlighting`, `neovim`; casks `sublime-text`, `zed`, `alacritty`, `font-0xproto-nerd-font-mono` (Zed terminal font).

Loop over arrays with `brew install` / `brew install --cask`; brew itself skips already-installed packages.

## Phase 3 — macOS defaults

Replicating `modules/darwin/default.nix` system settings:

- Dock: `autohide true`, `show-recents false`, `magnification true`, `tilesize 24`, `largesize 32`
- Finder: `AppleShowAllExtensions true`, `_FXShowPosixPathInTitle true`
- Keyboard: `InitialKeyRepeat 15`, `KeyRepeat 2` (NSGlobalDomain)
- Scrolling: `com.apple.swipescrolldirection false`
- TouchID for sudo: write `auth sufficient pam_tid.so` to `/etc/pam.d/sudo_local` (requires sudo; survives OS updates unlike editing `/etc/pam.d/sudo`)
- Dock apps in order via `dockutil --remove all` then `dockutil --add` for each of: Brave Browser, Spotify, Sublime Text, Zed, Slack (paths under `/Applications`)
- `killall Dock Finder` to apply

Keyboard layout (us/colemak) cannot be set reliably via `defaults`; print as a manual step.

## Phase 4 — Shell (zsh)

- Install oh-my-zsh unattended (`RUNZSH=no KEEPZSHRC=yes` official installer) if `~/.oh-my-zsh` missing
- Write `~/.zshrc` (backup existing to `~/.zshrc.bak`):
  - `ZSH_THEME="agnoster"`
  - `plugins=(helm kubectl kubectx sudo brew common-aliases fzf vscode)`
  - History: `HISTSIZE=999999`, `SAVEHIST=999999`, `EXTENDED_HISTORY`, `HIST_IGNORE_ALL_DUPS`
  - Source brew-installed `zsh-autosuggestions` and `zsh-syntax-highlighting`
  - `export PAGER=less EDITOR=vim`, `export DEFAULT_USER="$(whoami)"`, `PATH="$HOME/.local/bin:$PATH"`
  - Aliases: `ls="ls -la --color=auto -F"` (drop `nixswitch`/`nixup` — no Nix)
  - `eval "$(brew shellenv)"` so brew is on PATH in new shells

## Phase 5 — App configs

Each file backed up to `.bak` if present, then written:

- `~/.gitconfig` — `[user] name/email` via `git config --global`
- `~/.config/zed/settings.json` — agent block (anthropic / claude-sonnet-4), hour_format hour24, vim_mode false, load_direnv shell_hook, base_keymap VSCode, show_whitespaces all, ui_font_size 15, buffer_font_size 12, theme "Solarized Dark", tab_size 2, plus full `terminal` block from `terminal.nix` (alternate_scroll off, blinking on, copy_on_select, dock bottom, detect_venv, TERM env, font 0xProto Nerd Font Mono, working_directory current_project_directory)
- `~/.config/alacritty/alacritty.toml` — font size 14, embedded Solarized Dark color scheme
- `~/.config/bat/config` — `--theme="TwoDark"`

## Error handling & UX

- `set -euo pipefail`
- Colored `log`/`warn`/`error`/`success` helpers matching `rebuild.sh` style
- Each phase announces itself; failures abort with a clear message
- Final summary lists manual steps:
  - Install Bitwarden extension in Brave (declarative extension install not replicable)
  - Set keyboard layout to Colemak in System Settings
  - Log out/in for keyboard repeat settings to take effect

## Not replicated (documented limitations)

- `pwnvim` Nix flake (plain neovim instead)
- Declarative Brave/Bitwarden extension
- Nix generations/rollback semantics (`rebuild.sh rollback`, `clean`) — no equivalent
- `mac-app-util` Spotlight fixes — unnecessary, apps land in `/Applications` via brew

## Testing

- `bash -n bootstrap.sh` syntax check
- shellcheck clean
- Dry review of generated dotfiles content (write to temp HOME and inspect)
