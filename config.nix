# Centralized configuration for the Nix Darwin setup
# This file contains all the main configuration variables that can be easily modified
{
  # User configuration
  user = {
    username = "gentoosu";
    fullName = "Mike";
    email = ""; # Add your email if desired
  };

  # System configuration
  system = {
    hostName = "Mikes-MacBook-Pro";
    platform = "aarch64-darwin";
    timeZone = null; # Set to your timezone if needed, e.g., "America/New_York"
  };

  # Application preferences
  apps = {
    # Applications to install via Nix
    nixPackages = [
      "ansible"
      "awscli"
      "cloudflared"
      "curl"
      "docker"
      "dos2unix"
      "git"
      "google-cloud-sdk"
      "kubernetes-helm"
      "htop"
      "iftop"
      "iperf3"
      "jq"
      "postgresql"
      "kubectl"
      "kubectx"
      "kustomize"
      "nmap"
      "ripgrep"
      "terraform"
      "tree"
      "watch"
      "yq"
      "spotify"
      "slack"
    ];

    # Applications to install via Homebrew casks
    homebrewCasks = [
      "sublime-text"
    ];

    # Dock applications (in order of appearance)
    dockApps = [
      "Brave Browser"      # Via Home Manager
      "Spotify"           # Via Nix
      "Sublime Text"      # Via Homebrew
      "Zed"              # Via Home Manager  
      "Slack"            # Via Nix
      "Alacritty"        # Via Home Manager
    ];
  };

  # Development environment preferences
  development = {
    editor = "vim";
    pager = "less";
    shell = "zsh";
    
    # Git configuration
    git = {
      enable = true;
      # userName = "Your Name";  # Uncomment and set if desired
      # userEmail = "your@email.com";  # Uncomment and set if desired
    };

    # Terminal preferences
    terminal = {
      font = {
        size = 14;
      };
      theme = "solarized_dark";
    };
  };

  # macOS system preferences
  macOS = {
    dock = {
      autohide = true;
      showRecents = false;
      magnification = true;
      tileSize = 24;
      largeSize = 32;
    };

    finder = {
      showAllExtensions = true;
      showPosixPath = true;
    };

    keyboard = {
      initialKeyRepeat = 15;
      keyRepeat = 2;
      layout = "us";
      variant = "colemak";  # Change to "" for standard US layout
    };

    mouse = {
      naturalScrolling = false;  # Disable natural scrolling
    };

    security = {
      touchIdForSudo = true;
    };
  };

  # Shell configuration
  shell = {
    zsh = {
      theme = "agnoster";
      plugins = [
        "git"
        "helm"
        "kubectl"
        "kubectx"
        "sudo"
        "brew"
        "common-aliases"
        "fzf"
        "vscode"
      ];
      
      aliases = {
        ls = "ls --color=auto -F";
        nixswitch = "sudo ./result/sw/bin/darwin-rebuild switch --flake ~/git/nix-config/.#";
        nixup = "pushd ~/git/nix-config; nix flake update; nixswitch; popd";
      };
    };
  };

  # Homebrew configuration
  homebrew = {
    enable = true;
    cleanup = "zap";  # Options: "none", "uninstall", "zap"
    
    # Mac App Store applications
    masApps = {
      # Add Mac App Store apps here
      # "App Name" = 123456789;  # App Store ID
    };
  };
}