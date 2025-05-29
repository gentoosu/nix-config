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
  };

  outputs = inputs: {
    darwinConfigurations.Mikes-MacBook-Pro = inputs.darwin.lib.darwinSystem {
      system = "x86_64-darwin";
      pkgs = import inputs.nixpkgs {system = "x86_64-darwin";};
      modules = [
        ({pkgs, ...}: {
          # Add darwin prefs/configs
          programs.zsh.enable = true;
          environment.shells = [pkgs.bash pkgs.zsh];
          #environment.loginShell = pkgs.zsh;
          environment.systemPackages = [pkgs.coreutils];
          nix.extraOptions = ''
            experimental-features = nix-command flakes
          '';
          system.keyboard.enableKeyMapping = true;
          #fonts.fontDir.enable = true;
          fonts.packages = [
              pkgs.powerline
              ];
            })
          ];
          #services.nix-daemon.enable = true;
      #          system.primaryUser = "gentoosu";
          system.defaults.finder.AppleShowAllExtensions = true;
          system.defaults.finder._FXShowPosixPathInTitle = true;
          system.defaults.dock.autohide = true;
          system.defaults.NSGlobalDomain.InitialKeyRepeat = 14;
          system.defaults.NSGlobalDomain.KeyRepeat = 1;
          system.stateVersion = 6;
        })
        inputs.home-manager.darwinModules.home-manager
        {
          users.users.gentoosu = {
            name = "Mike";
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
                home.packages = [pkgs.ripgrep pkgs.curl];
                home.homeDirectory = "/Users/gentoosu";
                home.sessionVariables = {
                  PAGER = "less";
                  EDITOR = "vmim";
                };
                programs.bat.enable = true;
                programs.bat.config.theme = "TwoDark";
                programs.fzf.enable = true;
                programs.fzf.enableZshIntegration = true;
                programs.git.enable = true;
                programs.zsh.enable = true;
                programs.zsh.enableCompletion = true;
                programs.zsh.enableAutosuggestions = true;
                programs.zsh.enableSyntaxHighlighting = true;
                programs.zsh.shellAliases = {ls = "ls --color=auto -F";};
              })
            ];
          };
        }
      ];
    };
  };
}
