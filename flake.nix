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
        ./modules/darwin

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
              ./modules/home-manager
            ];
          };
        }
      ];
    };
  };
}
