# Nix Darwin Configuration

A comprehensive Nix Darwin setup for macOS built on [Determinate Nix](https://determinate.systems/), with Home Manager integration and a username variable system for easy customization.

## Features

- **Determinate Nix**: The Nix installation and daemon are managed by `determinate-nixd`, pinned and updated declaratively through this flake
- **Username Variable**: Easy username changes in one location
- **Home Manager Integration**: User-level package and dotfile management
- **Homebrew Integration**: Declarative Homebrew package management
- **Development Environment**: Pre-configured shell, editor, and development tools
- **Modular Structure**: Clean separation of system and user configurations

## Prerequisites

### Install Determinate Nix

Download and run the macOS package installer:

- [Determinate.pkg (Universal)](https://install.determinate.systems/determinate-pkg/stable/Universal)

Or install from the terminal:

```bash
curl -fsSL https://install.determinate.systems/nix | sh -s -- install --determinate
```

Flakes and `nix-command` are enabled out of the box — no extra configuration needed. If a Mac already has upstream Nix installed, uninstall it first (the installer will detect it and guide you).

## Quick Start

### 1. Clone this repository
```bash
git clone <your-repo-url> ~/git/nix-config
cd ~/git/nix-config
```

### 2. Customize your configuration
Edit `flake.nix` to match your preferences. Look for the configuration variables at the top of the `outputs` section:

```nix
# Configuration variables - easily customizable
username = "your-username";  # Change from "gentoosu"
system = "aarch64-darwin";   # or "x86_64-darwin" for Intel Macs
```

The configuration is published as `darwinConfigurations.default` and always targeted by that fixed name, so it applies identically to any Mac regardless of its hostname.

### 3. First activation

The Determinate installer writes `/etc/nix/nix.custom.conf` at install time. This flake manages that file declaratively, so on each new machine you must move the installer's copy aside once before the first activation:

```bash
sudo mv /etc/nix/nix.custom.conf /etc/nix/nix.custom.conf.before-nix-darwin
```

Then build and activate (nix-darwin isn't installed yet on a fresh machine, so bootstrap it with `nix run`):

```bash
# Test the configuration first
nix build .#darwinConfigurations.default.system

# Apply the configuration
sudo nix run nix-darwin -- switch --flake .#default
```

After the first activation, `darwin-rebuild` is on your PATH and subsequent rebuilds use it directly (or via `./rebuild.sh`):

```bash
sudo darwin-rebuild switch --flake ~/git/nix-config#default
```

## How Determinate Nix fits in

nix-darwin normally manages the Nix installation itself (daemon, `nix.conf`, garbage collection). Under Determinate, `determinate-nixd` owns all of that instead. This flake wires that up with the `determinate` input and its darwin module:

```nix
determinate.darwinModules.default
{
  determinateNix.enable = true;
}
```

`determinateNix.enable = true` disables nix-darwin's built-in Nix management, so the `nix.*` options (`nix.settings`, `nix.gc`, `nix.extraOptions`, etc.) are intentionally unused in this config. To set custom Nix daemon settings (substituters, trusted keys, etc.), use the module instead:

```nix
determinateNix.customSettings = {
  extra-substituters = "https://ryoppippi.cachix.org";
  extra-trusted-public-keys = "ryoppippi.cachix.org-1:b2LbtWNvJeL/qb1B6TYOMK+apaCps4SCbzlPRfSQIms=";
};
```

(This exact block is live in the config: it registers the binary cache for the [nix-claude-code](https://github.com/ryoppippi/nix-claude-code) input, which repackages Anthropic's official prebuilt Claude Code binaries as `pkgs.claude-code` via its overlay.)

These are written to `/etc/nix/nix.custom.conf`, the file Determinate reserves for user overrides. Determinate Nix itself is upgraded by updating the flake lock (`nix flake update determinate`) and rebuilding — not by re-running the installer.

## Configuration Structure

```
nix-config/
├── flake.nix               # Main flake definition with configuration variables
├── flake.lock              # Locked dependencies
├── rebuild.sh              # Helper script for rebuilding configuration
├── modules/
│   ├── darwin/
│   │   └── default.nix     # macOS system configuration
│   └── home-manager/
│       ├── default.nix     # User environment configuration
│       ├── agenix.nix      # Encrypted secret delivery (see Secrets below)
│       └── packages/       # Locally packaged tools not in nixpkgs
└── README.md               # This file
```

## Secrets

MCP servers need credentials (a Home Assistant token, a Context7 API key,
Prism Central login details). Those are managed with
[agenix](https://github.com/ryantm/agenix) and stored encrypted in a separate
private repo, **[nix-secrets](https://github.com/gentoosu/nix-secrets)**, which
this flake pulls in as an input.

### How the pieces fit

| Where | What |
|-------|------|
| `nix-secrets/*.age` | The encrypted values. Safe at rest; fetched into the Nix store as ciphertext. |
| `nix-secrets/secrets.nix` | agenix CLI recipient rules -- which pubkeys each `.age` file is encrypted to. Not a Nix module. |
| `modules/home-manager/agenix.nix` | The `age.secrets` declarations: which secrets exist and where they get decrypted to. |
| `modules/home-manager/default.nix` | The MCP servers, referencing secrets via `secret "name"`. |

Decryption uses `~/.ssh/id_ed25519`, which must be passphrase-less so it can
run unattended. agenix's **home-manager** module is used rather than its
nix-darwin one, because only the home-manager module installs a `RunAtLoad`
launchd agent -- the darwin module's `/run/agenix` ramdisk vanishes on reboot
and does not come back until the next `darwin-rebuild switch`.

Plaintext lands in `$(getconf DARWIN_USER_TEMP_DIR)/agenix.d/<generation>/`,
which macOS clears on reboot. `~/.secrets/<name>` is a stable symlink into it,
and that symlink is what the generated MCP wrapper scripts `cat` at launch. No
plaintext ever enters the Nix store or a durable file in your home directory.

### Editing a secret

```sh
cd ~/git/personal/nix-secrets
agenix -e ha-token.age          # opens $EDITOR on the plaintext
git commit -am "Rotate HA token" && git push

cd ~/git/personal/nix-config
nix flake update nix-secrets    # required -- flake.lock pins nix-secrets by revision
./rebuild.sh switch
```

Pushing to nix-secrets alone changes nothing on the machine. The `nix flake
update nix-secrets` step is what moves the pinned revision.

### Adding a secret

1. Add `"name.age".publicKeys = allKeys;` to `nix-secrets/secrets.nix`, then
   `agenix -e name.age`.
2. Add an `age.secrets.name` block to `modules/home-manager/agenix.nix`.
3. Reference it as `secret "name"` in `modules/home-manager/default.nix`.

### Adding a machine

Append the new Mac's `~/.ssh/id_ed25519.pub` to `allKeys` in
`nix-secrets/secrets.nix`, run `agenix -r` to re-encrypt everything, then push.
You need an existing recipient key on hand to rekey.

### Troubleshooting

Decryption runs out of a launchd agent, so its output is not on your terminal:

```sh
cat ~/Library/Logs/agenix/stderr
ls -l ~/.secrets/                 # each entry should be a symlink into $TMPDIR
launchctl kickstart -k gui/$(id -u)/org.nix-community.home.activate-agenix
```

`nix-secrets` is fetched over SSH, so evaluation needs your SSH agent.
`rebuild.sh` already runs `nix build` as you before escalating to `sudo
darwin-rebuild switch`, so the input is in the store by the time root
evaluates. Running `sudo darwin-rebuild` directly on a cold store will fail to
fetch it.

## Customization Guide

### Changing Username
1. Edit `flake.nix` and change the username passed to `mkDarwin` in `darwinConfigurations.default`
2. Rebuild: `sudo darwin-rebuild switch --flake ~/git/nix-config#default`

### Adding a Mac with a Different Login (e.g. work laptop)
The shared config is built by the `mkDarwin` function, which takes the machine's login username. Add a one-line entry in `flake.nix`:

```nix
darwinConfigurations.work = mkDarwin "work-username";
```

Then on that machine, bootstrap with `sudo nix run nix-darwin -- switch --flake .#work` and afterwards rebuild with:

```bash
CONFIG_NAME=work ./rebuild.sh switch
```

### Adding Applications

#### Nix Packages
Edit `modules/home-manager/default.nix` and add packages to the `home.packages` list:

```nix
home.packages = [
  pkgs.firefox
  pkgs.vscode
  # ... existing packages
];
```

#### Homebrew Casks
Edit `modules/darwin/default.nix` and add casks to the `homebrew.casks` list:

```nix
homebrew = {
  enable = true;
  casks = [
    "sublime-text"
    "discord"
    "figma"
    # ... other casks
  ];
};
```

#### Dock Applications
Edit `modules/darwin/default.nix` and update the `system.defaults.dock.persistent-apps` list:

```nix
system.defaults.dock.persistent-apps = [
  "/Users/${username}/Applications/Home Manager Apps/Firefox.app"
  "/Applications/Discord.app"
  # ... other apps
];
```

### macOS System Preferences
Customize system settings in `modules/darwin/default.nix`:

```nix
# Dock settings
system.defaults.dock.autohide = false;        # Show dock always
system.defaults.dock.tilesize = 36;          # Larger dock icons

# Keyboard settings
system.defaults.NSGlobalDomain.InitialKeyRepeat = 10;
system.defaults.NSGlobalDomain.KeyRepeat = 1;

# Finder settings
system.defaults.finder.AppleShowAllExtensions = true;
```

For user-specific keyboard settings, edit `modules/home-manager/default.nix`:

```nix
home.keyboard = {
  layout = "us";          # Standard US layout
  variant = "";           # Remove Colemak
};
```

### Development Environment
Configure your development tools in `modules/home-manager/default.nix`:

```nix
# Session variables
home.sessionVariables = {
  PAGER = "less";
  EDITOR = "code";          # Use VS Code instead of vim
};

# Terminal settings
programs.alacritty = {
  enable = true;
  theme = "nord";         # Change terminal theme
  settings = {
    font = {
      size = 16;         # Larger font
    };
  };
};

# Git configuration
programs.git = {
  enable = true;
  userName = "Your Name";
  userEmail = "your@email.com";
};
```

## Common Commands

### Update and rebuild
```bash
# Using the helper script
./rebuild.sh switch

# Quick alias (defined in shell config)
nixup

# Manual commands
cd ~/git/nix-config
nix flake update
sudo darwin-rebuild switch --flake ~/git/nix-config#default
```

### Build without applying
```bash
nix build .#darwinConfigurations.default.system
```

### Check configuration
```bash
nix flake check
```

### Show available outputs
```bash
nix flake show
```

### Check Determinate Nix status
```bash
determinate-nixd status
```

## Included Applications

### Development Tools
- Git, Docker, Kubernetes tools (kubectl, helm, kubectx)
- Cloud tools (AWS CLI, Google Cloud SDK)
- Network tools (curl, nmap, iperf3)
- Text processing (jq, yq, ripgrep)
- System monitoring (htop, iftop)

### Applications
- **Terminal**: Alacritty with Solarized Dark theme
- **Editor**: Neovim (pwnvim), Zed, Sublime Text
- **Browser**: Brave with Bitwarden extension
- **Communication**: Slack, Spotify
- **Shell**: Zsh with Oh My Zsh (Agnoster theme)

## Troubleshooting

### "Unexpected files in /etc, aborting activation"
On a machine's first activation, nix-darwin refuses to overwrite files it doesn't recognize — typically `/etc/nix/nix.custom.conf`, written by the Determinate installer. Move it aside and retry:

```bash
sudo mv /etc/nix/nix.custom.conf /etc/nix/nix.custom.conf.before-nix-darwin
```

The installer's copy contains only comments, so nothing is lost.

### "Determinate detected, aborting activation"
This means a config without `determinateNix.enable = true` (or `nix.enable = false`) is being activated on a machine running Determinate — for example, an old branch of this repo. Rebuild from a branch that includes the Determinate module.

### Homebrew Integration Issues
Ensure Homebrew is in your PATH:
```bash
echo 'export PATH="/opt/homebrew/bin:$PATH"' >> ~/.zprofile
```

### Flake Lock Issues
If dependencies are outdated:
```bash
nix flake update
```

## Post-Installation Notes

- **Logout/Login Required**: Some settings (like key repeat rates) require a logout/login cycle
- **Application Permissions**: Grant necessary permissions to applications when prompted
- **Spotlight Indexing**: New applications may take time to appear in Spotlight

## Known Limitations

- iTerm2 theme must be set manually
- System default browser setting requires manual configuration
- Browser extensions need manual installation
- Some macOS settings may require System Preferences access

## Contributing

1. Create a feature branch: `git checkout -b feature/your-improvement`
2. Make your changes to `flake.nix` or module files
3. Test with `nix flake check` or `./rebuild.sh build --dry-run`
4. Submit a pull request

## Helper Script

The included `rebuild.sh` script provides convenient commands:

```bash
./rebuild.sh build      # Build without applying
./rebuild.sh switch     # Build and apply configuration
./rebuild.sh update     # Update flake inputs and rebuild
./rebuild.sh check      # Check configuration for errors
./rebuild.sh show       # Show available outputs
./rebuild.sh clean      # Clean old generations
./rebuild.sh rollback   # Rollback to previous generation
./rebuild.sh help       # Show help
```

Options:
- `--dry-run`: Show what would happen without doing it
- `--verbose`: Show detailed output

## Resources

- [Determinate Nix Documentation](https://docs.determinate.systems/)
- [Using Determinate with nix-darwin](https://docs.determinate.systems/guides/nix-darwin/)
- [Nix Darwin Documentation](https://github.com/nix-darwin/nix-darwin)
- [Home Manager Documentation](https://github.com/nix-community/home-manager)
- [Nix Flakes Tutorial](https://nixos.wiki/wiki/Flakes)
- [macOS Defaults Reference](https://macos-defaults.com/)
