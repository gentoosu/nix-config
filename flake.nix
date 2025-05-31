{
  description = "Mike's MBP flake";
  inputs = {
    # Define our software
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # Manage configs, links things to home dir
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Control system level software/settings(fonts, etc)
    darwin.url = "github:lnl7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    pwnvm.url = "github:zmre/pwnvim";
  };

  outputs = inputs: {
    darwinConfigurations.Mikes-MacBook-Pro = inputs.darwin.lib.darwinSystem {
      #system = "x86_64-darwin";
      pkgs = import inputs.nixpkgs {
        system = "x86_64-darwin";
        config.allowUnfree = true;
      };
      modules = [
        ({pkgs, ...}: {
          # Add darwin prefs/configs
          programs.zsh.enable = true;
          environment.shells = [pkgs.bash pkgs.zsh];
          #environment.loginShell = pkgs.zsh;
          environment.systemPackages = [
            pkgs.coreutils
            pkgs.iterm2
          ];
          environment.systemPath = ["/opt/homebrew/bin"];
          nix.extraOptions = ''
            experimental-features = nix-command flakes
          '';

          system.keyboard = {
            enableKeyMapping = true;
          };

          #fonts.fontDir.enable = true;
          fonts.packages = [
            pkgs.powerline
          ];

          #services.nix-daemon.enable = true;
          security.pam.services.sudo_local.touchIdAuth = true;

          system.primaryUser = "gentoosu";
          system.defaults.finder.AppleShowAllExtensions = true;
          system.defaults.finder._FXShowPosixPathInTitle = true;
          system.defaults.dock.autohide = false;
          system.defaults.dock.show-recents = false;
          system.defaults.dock.magnification = true;
          system.defaults.dock.tilesize = 24;
          system.defaults.dock.largesize = 32;
          system.defaults.dock.persistent-apps = [
            "/Applications/Brave Browser.app"
            "/Applications/iTerm.app"
            "/Applications/Spotify.app"
            "/Applications/Sublime Text.app"
            "/Applications/Visual Studio Code.app"
            "/Applications/Slack.app"
          ];
          system.defaults.NSGlobalDomain.InitialKeyRepeat = 14;
          system.defaults.NSGlobalDomain.KeyRepeat = 4;
          system.defaults.NSGlobalDomain."com.apple.swipescrolldirection" = false;

          ### DO NOT MODIFY, for backwards compatibility
          system.stateVersion = 6;

          homebrew = {
            enable = true;
            caskArgs.no_quarantine = true;
            global.brewfile = true;
            masApps = {};
            casks = ["visual-studio-code" "spotify" "slack" "alacritty" "sublime-text" "google-cloud-sdk" "brave-browser"];
            taps = ["fujiapple852/trippy"];
            brews = ["trippy"];
          };
        })

        inputs.home-manager.darwinModules.home-manager
        {
          users.users.gentoosu = {
            #name = "Mike";
            home = "/Users/gentoosu";
          };

          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.gentoosu.imports = [
              ({pkgs, ...}: {
                #Specify home-manager configs
                #DO NOT CHANGE version
                home.stateVersion = "25.05";
                home.packages = [
                  pkgs.ansible
                  pkgs.awscli
                  pkgs.curl
                  pkgs.dos2unix
                  pkgs.git
                  pkgs.google-cloud-sdk
                  pkgs.kubernetes-helm
                  pkgs.htop
                  pkgs.iftop
                  pkgs.iperf3
                  pkgs.jq
                  pkgs.kubectl
                  pkgs.kubectx
                  pkgs.kustomize
                  pkgs.nmap
                  pkgs.ripgrep
                  pkgs.terraform
                  pkgs.tree
                  pkgs.watch
                  pkgs.yq
                  inputs.pwnvm.packages."x86_64-darwin".default
                ];

                home.homeDirectory = "/Users/gentoosu";

                home.keyboard = {
                  layout = "us";
                  variant = "colemak";
                };

                home.sessionVariables = {
                  PAGER = "less";
                  EDITOR = "vmim";
                };

                programs.bat = {
                  enable = true;
                  config.theme = "TwoDark";
                };

                programs.fzf = {
                  enable = true;
                  enableZshIntegration = true;
                };

                programs.git.enable = true;

                programs.zsh = {
                  enable = true;
                  enableCompletion = true;
                  oh-my-zsh.enable = true;
                  oh-my-zsh.theme = "agnoster";
                  autosuggestion.enable = true;
                  syntaxHighlighting.enable = true;
                  shellAliases = {ls = "ls --color=auto -F";};
                  oh-my-zsh.plugins = ["git" "helm" "kubectl" "kubectx" "sudo" "brew" "common-aliases" "fzf" "vscode"];
                };

                #programs.homebrew.iterm2.theme = "Solarized Dark";

                programs.vscode = {
                  enable = true;
                  extensions = with pkgs.vscode-extensions; [
                    bbenoist.nix
                    brettm12345.nixfmt-vscode
                    eamodio.gitlens
                    hashicorp.terraform
                    ms-python.vscode-pylance
                    ms-python.python
                    hashicorp.hcl
                    hashicorp.terraform
                    wholroyd.jinja
                    redhat.vscode-yaml
                    ms-kubernetes-tools.vscode-kubernetes-tools
                  ];
                };
              })
            ];
          };
        }
      ];
    };
  };
}
