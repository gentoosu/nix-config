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

    # Determinate Nix (manages the Nix installation/daemon)
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";

    # Anthropic's official prebuilt Claude Code binaries, repackaged and
    # refreshed hourly (overlay provides pkgs.claude-code). No nixpkgs.follows:
    # the "build" just fetches and wraps an upstream binary, so it costs
    # seconds even when the Cachix cache hasn't caught up to a new release.
    nix-claude-code.url = "github:ryoppippi/nix-claude-code";

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

  outputs = inputs@{nixpkgs, home-manager, darwin, pwnvim, mac-app-util, nix-homebrew, homebrew-core, homebrew-cask, determinate, nix-claude-code, ...}:
    let
      system = "aarch64-darwin";

      # Build the shared system config for a given login user. Every Mac
      # runs the same config; only the username differs per machine.
      mkDarwin = username: darwin.lib.darwinSystem {
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [nix-claude-code.overlays.default];
        };

        specialArgs = { inherit username; };

        modules = [
          ./modules/darwin

          determinate.darwinModules.default
          {
            # Determinate Nix owns the Nix installation and daemon;
            # this also disables nix-darwin's built-in Nix management.
            determinateNix.enable = true;

            # Binary cache for the nix-claude-code input's builds
            determinateNix.customSettings = {
              extra-substituters = "https://ryoppippi.cachix.org";
              extra-trusted-public-keys = "ryoppippi.cachix.org-1:b2LbtWNvJeL/qb1B6TYOMK+apaCps4SCbzlPRfSQIms=";
            };
          }

          mac-app-util.darwinModules.default
          home-manager.darwinModules.home-manager
          {
            users.users.${username} = {
              home = "/Users/${username}";
            };

            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;

              # Rename pre-existing unmanaged files (e.g. a hand-written
              # ~/.claude/settings.json) to *.hm-backup instead of aborting
              # activation. Needed on every machine's first switch.
              backupFileExtension = "hm-backup";
              extraSpecialArgs = {
                inherit pwnvim username;
              };
              users.${username}.imports = [
                ./modules/home-manager
              ];

              sharedModules = [
                mac-app-util.homeManagerModules.default
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
    in
    {
      # Personal Macs; targeted as .#default so hostname doesn't matter.
      darwinConfigurations.default = mkDarwin "gentoosu";

      # Machines with a different login get their own one-liner, e.g.:
      #   darwinConfigurations.work = mkDarwin "work-username";
      # then switch with: CONFIG_NAME=work ./rebuild.sh switch
    };
}
