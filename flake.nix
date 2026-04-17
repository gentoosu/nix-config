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

    # Neovim flake
    pwnvim.url = "github:zmre/pwnvim";

    # Utility to fix pkgs installs/Spotlight
    mac-app-util.url = "github:hraban/mac-app-util";

    # Nix Homebrew integration
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    # Homebrew taps for declarative management
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
  };

  outputs = inputs@{nixpkgs, home-manager, darwin, pwnvim, mac-app-util, nix-homebrew, homebrew-core, homebrew-cask, ...}: 
    let
      # Configuration variables - easily customizable
      username = "gentoosu";
      system = "aarch64-darwin";
      hostName = "Mikes-MacBook-Pro";
    in
    {
      darwinConfigurations.${hostName} = darwin.lib.darwinSystem {
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
        
        specialArgs = { inherit username; };
        
        modules = [
          ./modules/darwin
          mac-app-util.darwinModules.default
          home-manager.darwinModules.home-manager
          {
            users.users.${username} = {
              home = "/Users/${username}";
            };

            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = { 
                inherit pwnvim username; 
              };
              users.${username}.imports = [
                ./modules/home-manager
              ];
            };
          }

          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              # Install Homebrew under the default prefix
              enable = true;

              # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
              enableRosetta = true;

              # User owning the Homebrew prefix
              user = username;

              # Declarative tap management
              taps = {
                "homebrew/homebrew-core" = homebrew-core;
                "homebrew/homebrew-cask" = homebrew-cask;
              };

              # Enable fully-declarative tap management
              # With mutableTaps disabled, taps can no longer be added imperatively with `brew tap`
              mutableTaps = false;
            };
          }
        ];
      };
    };
}
