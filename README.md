Prerequisites:

Install nix:

  > h <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install)

Install homebrew:

  > /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"


###################################

Initial config/test:

  nix --extra-experimental-features "nix-command flakes" build .#darwinConfigurations.Mikes-MacBook-Pro.system

Subsequent updates:

  sudo ./result/sw/bin/darwin-rebuild switch --flake /git/nix-tutorial.
