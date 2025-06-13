Prerequisites:

Install nix:

  > sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install)

Install homebrew:

  > /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"


###################################

Initial config/test:
  > nix --extra-experimental-features "nix-command flakes" build .#darwinConfigurations.{{ YOUR COMPUTER NAME FROM flakes.nix}}.system

Subsequent updates:

 > sudo darwin-rebuild switch --flake /Users/{ username }/git/nix-config/.#

Issues I haven't figured out yet:

- Set iTerm2 theme
- Set system default browser
- Install Brave/Chrome extensions
- Pass username as a variable


*** Some settings require you to logout/login before taking affect, ex: keyrepeat
