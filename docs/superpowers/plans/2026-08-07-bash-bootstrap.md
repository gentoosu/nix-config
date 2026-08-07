# Bash Bootstrap Script Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A single portable `bootstrap.sh` that replicates this nix-darwin + home-manager config on any Mac without Nix.

**Architecture:** One bash file: a CONFIGURATION section at the top (mirroring `config.nix`), helper functions (logging, backup), then one function per phase (Homebrew, packages, macOS defaults, shell, app configs) called from `main`. A source guard (`BASH_SOURCE` check) lets tests source the file and call functions individually with `HOME` pointed at a temp dir.

**Tech Stack:** bash, Homebrew, `defaults`, `dockutil`, oh-my-zsh.

## Global Constraints

- Spec: `docs/superpowers/specs/2026-08-07-bash-bootstrap-design.md`
- Script must pass `bash -n` and `shellcheck` (if shellcheck is available)
- `set -euo pipefail` at top
- One-time bootstrap semantics; dotfiles backed up to `<file>.bak` before overwrite (only if no `.bak` exists yet)
- macOS only — abort on other platforms
- Do NOT actually run the full script during implementation (it would mutate this machine); verify via syntax checks, sourcing individual dotfile-writer functions with `HOME=$(mktemp -d)`, and `declare -f` checks

---

### Task 1: Script skeleton — config section, helpers, main guard

**Files:**
- Create: `bootstrap.sh`

**Interfaces:**
- Produces: `log`, `warn`, `error`, `success`, `backup_file <path>`, config arrays `FORMULAE`, `CASKS`, `DOCK_APPS`, vars `USERNAME GIT_NAME GIT_EMAIL INITIAL_KEY_REPEAT KEY_REPEAT DOCK_TILESIZE DOCK_LARGESIZE ALACRITTY_FONT_SIZE`, and `main` (later tasks append calls into `main`)

- [ ] **Step 1: Write `bootstrap.sh` with header, config, helpers, and guarded main**

```bash
#!/usr/bin/env bash
#
# bootstrap.sh — Portable macOS bootstrap replicating nix-config
# One-time setup: Homebrew packages, macOS defaults, zsh, app configs.
# Edit the CONFIGURATION section below, then run: ./bootstrap.sh
#
# Existing dotfiles are backed up to <file>.bak before being overwritten.

set -euo pipefail

# ============================================================
# CONFIGURATION — edit these before running
# ============================================================

USERNAME="${USERNAME:-$(whoami)}"
GIT_NAME="Mike Hershberger"
GIT_EMAIL="mike.hershberger@gmail.com"

# macOS preferences
INITIAL_KEY_REPEAT=15
KEY_REPEAT=2
DOCK_TILESIZE=24
DOCK_LARGESIZE=32
ALACRITTY_FONT_SIZE=14

# Homebrew formulae (CLI tools; replaces nix home.packages)
FORMULAE=(
  ansible awscli bat cloudflared coreutils curl docker dockutil dos2unix fzf
  git helm htop iftop iperf3 jq kubernetes-cli kubectx kustomize localstack
  neovim nmap postgresql ripgrep terragrunt tree uv watch yq
  zsh-autosuggestions zsh-syntax-highlighting
  hashicorp/tap/terraform
)

# Homebrew casks (GUI apps + fonts)
CASKS=(
  alacritty brave-browser font-0xproto-nerd-font font-meslo-lg-nerd-font
  google-chrome google-cloud-sdk rectangle slack spotify sublime-text zed
)

# Dock apps, in order (replaces system.defaults.dock.persistent-apps)
DOCK_APPS=(
  "/Applications/Brave Browser.app"
  "/Applications/Spotify.app"
  "/Applications/Sublime Text.app"
  "/Applications/Zed.app"
  "/Applications/Slack.app"
)

# ============================================================
# HELPERS
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()     { echo -e "${BLUE}[INFO]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }

# Backup a file to <file>.bak once (never clobber an existing backup)
backup_file() {
  local file="$1"
  if [[ -e "$file" && ! -e "$file.bak" ]]; then
    cp "$file" "$file.bak"
    log "Backed up $file to $file.bak"
  fi
}

# ============================================================
# MAIN
# ============================================================

main() {
  [[ "$(uname -s)" == "Darwin" ]] || error "This script is for macOS only"
  log "Bootstrapping macOS for user: $USERNAME"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
```

- [ ] **Step 2: Verify syntax and helper behavior**

Run:
```bash
cd /Users/gentoosu/git/personal/nix-config
bash -n bootstrap.sh
command -v shellcheck >/dev/null && shellcheck bootstrap.sh || echo "shellcheck unavailable, skipped"
tmp=$(mktemp -d)
echo "original" > "$tmp/testfile"
bash -c "source ./bootstrap.sh; backup_file '$tmp/testfile'"
grep -q original "$tmp/testfile.bak" && echo BACKUP-OK
```
Expected: `bash -n` silent, `BACKUP-OK` printed. Sourcing must NOT print "Bootstrapping" (guard works).

- [ ] **Step 3: Commit**

```bash
git add bootstrap.sh
git commit -m "feat: bootstrap.sh skeleton with config section and helpers"
```

---

### Task 2: Phase 1 & 2 — Homebrew install and packages

**Files:**
- Modify: `bootstrap.sh` (add functions before MAIN section; update `main`)

**Interfaces:**
- Consumes: `log/warn/error/success`, `FORMULAE`, `CASKS`
- Produces: `install_homebrew`, `install_packages`

- [ ] **Step 1: Add the two phase functions above the MAIN section**

```bash
# ============================================================
# PHASE 1: Homebrew
# ============================================================

install_homebrew() {
  log "Phase 1: Homebrew"
  if ! command -v brew >/dev/null 2>&1; then
    log "Installing Homebrew..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  # Put brew on PATH for this run (Apple Silicon vs Intel prefix)
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
  command -v brew >/dev/null 2>&1 || error "Homebrew installation failed"
  success "Homebrew ready"
}

# ============================================================
# PHASE 2: Packages
# ============================================================

install_packages() {
  log "Phase 2: Packages"
  local formula cask
  for formula in "${FORMULAE[@]}"; do
    brew install "$formula" || error "Failed to install formula: $formula"
  done
  for cask in "${CASKS[@]}"; do
    brew install --cask "$cask" || error "Failed to install cask: $cask"
  done
  # terraform-local was a nix package; closest equivalent is the pip tool via uv
  uv tool install terraform-local || warn "terraform-local install failed (non-fatal)"
  warn "pwnvim is a Nix flake and cannot be replicated; plain neovim was installed instead"
  success "Packages installed"
}
```

- [ ] **Step 2: Update `main` to call them**

Replace the `main()` body so it reads:
```bash
main() {
  [[ "$(uname -s)" == "Darwin" ]] || error "This script is for macOS only"
  log "Bootstrapping macOS for user: $USERNAME"
  install_homebrew
  install_packages
}
```

- [ ] **Step 3: Verify**

Run:
```bash
bash -n bootstrap.sh
command -v shellcheck >/dev/null && shellcheck bootstrap.sh || echo "shellcheck unavailable, skipped"
bash -c 'source ./bootstrap.sh; declare -f install_homebrew install_packages >/dev/null && echo FUNCS-OK'
```
Expected: `FUNCS-OK`. Do NOT run the functions (they install real software).

- [ ] **Step 4: Commit**

```bash
git add bootstrap.sh
git commit -m "feat: add Homebrew and package install phases"
```

---

### Task 3: Phase 3 — macOS defaults, TouchID sudo, dock layout

**Files:**
- Modify: `bootstrap.sh` (add functions above MAIN; update `main`)

**Interfaces:**
- Consumes: helpers, `DOCK_APPS`, `INITIAL_KEY_REPEAT`, `KEY_REPEAT`, `DOCK_TILESIZE`, `DOCK_LARGESIZE`
- Produces: `configure_macos_defaults`, `configure_touchid_sudo`, `configure_dock_apps`

- [ ] **Step 1: Add the phase functions**

```bash
# ============================================================
# PHASE 3: macOS defaults
# ============================================================

configure_touchid_sudo() {
  # Replaces security.pam.services.sudo_local.touchIdAuth
  if [[ ! -f /etc/pam.d/sudo_local ]] || ! grep -q pam_tid.so /etc/pam.d/sudo_local; then
    log "Enabling TouchID for sudo (may prompt for password)..."
    echo "auth       sufficient     pam_tid.so" | sudo tee /etc/pam.d/sudo_local >/dev/null
  fi
}

configure_dock_apps() {
  # Replaces system.defaults.dock.persistent-apps
  if ! command -v dockutil >/dev/null 2>&1; then
    warn "dockutil not found; skipping dock layout"
    return
  fi
  dockutil --remove all --no-restart
  local app
  for app in "${DOCK_APPS[@]}"; do
    if [[ -d "$app" ]]; then
      dockutil --add "$app" --no-restart
    else
      warn "Dock app not found, skipping: $app"
    fi
  done
}

configure_macos_defaults() {
  log "Phase 3: macOS defaults"

  # Dock (system.defaults.dock.*)
  defaults write com.apple.dock autohide -bool true
  defaults write com.apple.dock show-recents -bool false
  defaults write com.apple.dock magnification -bool true
  defaults write com.apple.dock tilesize -int "$DOCK_TILESIZE"
  defaults write com.apple.dock largesize -int "$DOCK_LARGESIZE"

  # Finder (system.defaults.finder.*)
  defaults write NSGlobalDomain AppleShowAllExtensions -bool true
  defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

  # Keyboard + scrolling (system.defaults.NSGlobalDomain.*)
  defaults write NSGlobalDomain InitialKeyRepeat -int "$INITIAL_KEY_REPEAT"
  defaults write NSGlobalDomain KeyRepeat -int "$KEY_REPEAT"
  defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false

  configure_touchid_sudo
  configure_dock_apps

  killall Dock 2>/dev/null || true
  killall Finder 2>/dev/null || true
  success "macOS defaults applied"
}
```

- [ ] **Step 2: Append `configure_macos_defaults` to `main`** (after `install_packages`)

- [ ] **Step 3: Verify**

```bash
bash -n bootstrap.sh
command -v shellcheck >/dev/null && shellcheck bootstrap.sh || echo "shellcheck unavailable, skipped"
bash -c 'source ./bootstrap.sh; declare -f configure_macos_defaults configure_touchid_sudo configure_dock_apps >/dev/null && echo FUNCS-OK'
```
Expected: `FUNCS-OK`. Do NOT run these (they mutate this machine's settings).

- [ ] **Step 4: Commit**

```bash
git add bootstrap.sh
git commit -m "feat: add macOS defaults, TouchID sudo, and dock phase"
```

---

### Task 4: Phase 4 — oh-my-zsh and .zshrc

**Files:**
- Modify: `bootstrap.sh`

**Interfaces:**
- Consumes: helpers, `backup_file`
- Produces: `install_oh_my_zsh`, `write_zshrc` (respects `$HOME`, testable in temp dir)

- [ ] **Step 1: Add the phase functions**

```bash
# ============================================================
# PHASE 4: Shell (zsh + oh-my-zsh)
# ============================================================

install_oh_my_zsh() {
  log "Phase 4: Shell"
  if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    log "Installing oh-my-zsh..."
    RUNZSH=no KEEPZSHRC=yes /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  fi
}

write_zshrc() {
  backup_file "$HOME/.zshrc"
  local brew_prefix
  brew_prefix="$(brew --prefix 2>/dev/null || echo /opt/homebrew)"
  cat > "$HOME/.zshrc" <<EOF
# Managed by bootstrap.sh — edit the script, not this file
eval "\$(${brew_prefix}/bin/brew shellenv)"

export ZSH="\$HOME/.oh-my-zsh"
ZSH_THEME="agnoster"
plugins=(helm kubectl kubectx sudo brew common-aliases fzf vscode)

# History (programs.zsh.history.*)
HISTSIZE=999999
SAVEHIST=999999
setopt EXTENDED_HISTORY
setopt HIST_IGNORE_ALL_DUPS

source "\$ZSH/oh-my-zsh.sh"

# Session variables (home.sessionVariables + initContent)
export PAGER=less
export EDITOR=vim
export DEFAULT_USER="\$(whoami)"
export PATH="\$HOME/.local/bin:\$PATH"

alias ls="ls -la --color=auto -F"

# Brew-installed plugins (autosuggestion.enable / syntaxHighlighting.enable)
source "${brew_prefix}/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "${brew_prefix}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
EOF
  success ".zshrc written"
}
```

- [ ] **Step 2: Append `install_oh_my_zsh` and `write_zshrc` to `main`**

- [ ] **Step 3: Test `write_zshrc` against a temp HOME**

```bash
bash -n bootstrap.sh
tmp=$(mktemp -d)
echo "old zshrc" > "$tmp/.zshrc"
HOME="$tmp" bash -c 'source ./bootstrap.sh; write_zshrc'
grep -q 'old zshrc' "$tmp/.zshrc.bak" && echo BAK-OK
grep -q 'ZSH_THEME="agnoster"' "$tmp/.zshrc" && echo THEME-OK
grep -q 'HIST_IGNORE_ALL_DUPS' "$tmp/.zshrc" && echo HIST-OK
grep -q 'plugins=(helm kubectl kubectx sudo brew common-aliases fzf vscode)' "$tmp/.zshrc" && echo PLUGINS-OK
```
Expected: `BAK-OK`, `THEME-OK`, `HIST-OK`, `PLUGINS-OK`.

- [ ] **Step 4: Commit**

```bash
git add bootstrap.sh
git commit -m "feat: add zsh/oh-my-zsh phase with managed .zshrc"
```

---

### Task 5: Phase 5 — git, Zed, Alacritty, bat configs + summary

**Files:**
- Modify: `bootstrap.sh`

**Interfaces:**
- Consumes: helpers, `backup_file`, `GIT_NAME`, `GIT_EMAIL`, `ALACRITTY_FONT_SIZE`
- Produces: `configure_git`, `write_zed_settings`, `write_alacritty_config`, `write_bat_config`, `print_summary`

- [ ] **Step 1: Add the phase functions**

```bash
# ============================================================
# PHASE 5: App configs
# ============================================================

configure_git() {
  log "Phase 5: App configs"
  backup_file "$HOME/.gitconfig"
  git config --global user.name "$GIT_NAME"
  git config --global user.email "$GIT_EMAIL"
  success "git configured"
}

write_zed_settings() {
  local dir="$HOME/.config/zed"
  mkdir -p "$dir"
  backup_file "$dir/settings.json"
  cat > "$dir/settings.json" <<'EOF'
{
  "agent": {
    "enabled": true,
    "version": "2",
    "default_model": {
      "provider": "anthropic",
      "model": "claude-sonnet-4-20250514"
    }
  },
  "hour_format": "hour24",
  "vim_mode": false,
  "load_direnv": "shell_hook",
  "base_keymap": "VSCode",
  "show_whitespaces": "all",
  "ui_font_size": 15,
  "buffer_font_size": 12,
  "theme": "Solarized Dark",
  "tab_size": 2,
  "terminal": {
    "alternate_scroll": "off",
    "blinking": "on",
    "copy_on_select": true,
    "dock": "bottom",
    "detect_venv": {
      "on": {
        "directories": [".env", "env", ".venv", "venv"],
        "activate_script": "default"
      }
    },
    "env": {
      "TERM": ""
    },
    "font_family": "0xProto Nerd Font Mono",
    "working_directory": "current_project_directory"
  }
}
EOF
  success "Zed settings written"
}

write_alacritty_config() {
  local dir="$HOME/.config/alacritty"
  mkdir -p "$dir"
  backup_file "$dir/alacritty.toml"
  cat > "$dir/alacritty.toml" <<EOF
# Managed by bootstrap.sh — Solarized Dark theme
[font]
size = ${ALACRITTY_FONT_SIZE}

[colors.primary]
background = "#002b36"
foreground = "#839496"

[colors.normal]
black   = "#073642"
red     = "#dc322f"
green   = "#859900"
yellow  = "#b58900"
blue    = "#268bd2"
magenta = "#d33682"
cyan    = "#2aa198"
white   = "#eee8d5"

[colors.bright]
black   = "#002b36"
red     = "#cb4b16"
green   = "#586e75"
yellow  = "#657b83"
blue    = "#839496"
magenta = "#6c71c4"
cyan    = "#93a1a1"
white   = "#fdf6e3"
EOF
  success "Alacritty config written"
}

write_bat_config() {
  local dir="$HOME/.config/bat"
  mkdir -p "$dir"
  backup_file "$dir/config"
  echo '--theme="TwoDark"' > "$dir/config"
  success "bat config written"
}

print_summary() {
  echo ""
  success "Bootstrap complete!"
  echo ""
  warn "Manual steps remaining:"
  echo "  - Install the Bitwarden extension in Brave (declarative extension install is Nix-only)"
  echo "  - Set keyboard layout to Colemak: System Settings > Keyboard > Input Sources"
  echo "  - Log out and back in for keyboard repeat settings to take effect"
}
```

- [ ] **Step 2: Finalize `main`**

```bash
main() {
  [[ "$(uname -s)" == "Darwin" ]] || error "This script is for macOS only"
  log "Bootstrapping macOS for user: $USERNAME"
  install_homebrew
  install_packages
  configure_macos_defaults
  install_oh_my_zsh
  write_zshrc
  configure_git
  write_zed_settings
  write_alacritty_config
  write_bat_config
  print_summary
}
```

- [ ] **Step 3: Test the writers against a temp HOME**

```bash
bash -n bootstrap.sh
tmp=$(mktemp -d)
HOME="$tmp" bash -c 'source ./bootstrap.sh; configure_git; write_zed_settings; write_alacritty_config; write_bat_config'
HOME="$tmp" git config --global user.email | grep -q 'mike.hershberger@gmail.com' && echo GIT-OK
python3 -c "import json;json.load(open('$tmp/.config/zed/settings.json'))" && echo JSON-OK
grep -q 'size = 14' "$tmp/.config/alacritty/alacritty.toml" && echo FONT-OK
grep -q 'TwoDark' "$tmp/.config/bat/config" && echo BAT-OK
```
Expected: `GIT-OK`, `JSON-OK`, `FONT-OK`, `BAT-OK`.

- [ ] **Step 4: Commit**

```bash
git add bootstrap.sh
git commit -m "feat: add app config phase and completion summary"
```

---

### Task 6: Final verification and polish

**Files:**
- Modify: `bootstrap.sh` (chmod only, plus any shellcheck fixes)

- [ ] **Step 1: Make executable, full lint pass**

```bash
chmod +x bootstrap.sh
bash -n bootstrap.sh
command -v shellcheck >/dev/null && shellcheck bootstrap.sh || echo "shellcheck unavailable, skipped"
```
Expected: no shellcheck findings (fix any that appear).

- [ ] **Step 2: End-to-end dotfile dry test in temp HOME**

```bash
tmp=$(mktemp -d)
HOME="$tmp" bash -c 'source ./bootstrap.sh; write_zshrc; configure_git; write_zed_settings; write_alacritty_config; write_bat_config'
ls -la "$tmp" "$tmp/.config"
```
Expected: `.zshrc`, `.gitconfig`, `.config/{zed,alacritty,bat}` all present.

- [ ] **Step 3: Commit final state**

```bash
git add bootstrap.sh
git commit -m "chore: make bootstrap.sh executable, lint clean"
```
