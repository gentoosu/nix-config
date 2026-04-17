# Nix Darwin Configuration

A comprehensive Nix Darwin setup for macOS with Home Manager integration, featuring a username variable system for easy customization.

## Features

- **Username Variable**: Easy username changes in one location
- **Home Manager Integration**: User-level package and dotfile management
- **Homebrew Integration**: Declarative Homebrew package management
- **Development Environment**: Pre-configured shell, editor, and development tools
- **Modular Structure**: Clean separation of system and user configurations

## Prerequisites

### Install Nix
```bash
sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install)
```

### Install Homebrew
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

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
hostName = "Your-MacBook-Pro";  # Update to match your hostname
```

### 3. Initial build and activation
```bash
# Test the configuration first
nix --extra-experimental-features "nix-command flakes" build .#darwinConfigurations.Your-MacBook-Pro.system

# Apply the configuration
sudo darwin-rebuild switch --flake ~/git/nix-config/.#
```

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
│       └── default.nix     # User environment configuration
└── README.md               # This file
```

## Customization Guide

### Changing Username
1. Edit `flake.nix` and update the `username` variable in the `let` block
2. Update `hostName` if desired
3. Rebuild: `sudo darwin-rebuild switch --flake ~/git/nix-config/.#`

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
sudo darwin-rebuild switch --flake ~/git/nix-config/.#
```

### Build without applying
```bash
nix build .#darwinConfigurations.Your-MacBook-Pro.system
```

### Check configuration
```bash
nix flake check
```

### Show available outputs
```bash
nix flake show
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

### Permission Issues
If you encounter permission errors:
```bash
sudo chown -R $(whoami) /nix
```

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

- [Nix Darwin Documentation](https://github.com/LnL7/nix-darwin/)
- [Home Manager Documentation](https://github.com/nix-community/home-manager)
- [Nix Flakes Tutorial](https://nixos.wiki/wiki/Flakes)
- [macOS Defaults Reference](https://macos-defaults.com/)