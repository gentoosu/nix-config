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

    #Neovim flake
    pwnvim.url = "github:zmre/pwnvim";

    #Utility to fix pkgs installs/Spotlight
    mac-app-util.url = "github:hraban/mac-app-util";

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    # Optional: Declarative tap management
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };

  };

  outputs = inputs@{nixpkgs, home-manager, darwin, pwnvim, mac-app-util, nix-homebrew, homebrew-core, homebrew-cask,... }: {
    darwinConfigurations.Mikes-MacBook-Pro =
      darwin.lib.darwinSystem {
        #system = "aarch64-darwin";
        pkgs = import nixpkgs {
          #system = "x86_64-darwin";
          system = "aarch64-darwin";
          config.allowUnfree = true;
        };
        modules = [
          ./modules/darwin
          mac-app-util.darwinModules.default
          home-manager.darwinModules.home-manager
          {
            users.users.gentoosu = {
              #name = "Mike";
              home = "/Users/gentoosu";
            };

            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = { inherit pwnvim; };
              users.gentoosu.imports = [
                ./modules/home-manager
                #./modules/darwin/programs/zed-editor
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
              user = "gentoosu";

              # Optional: Declarative tap management
              taps = {
                  "homebrew/homebrew-core" = homebrew-core;
                  "homebrew/homebrew-cask" = homebrew-cask;
              };

              # Optional: Enable fully-declarative tap management
              #
              # With mutableTaps disabled, taps can no longer be added imperatively with `brew tap`.
              mutableTaps = false;
            };
          }

        ];
      };
  };
}
