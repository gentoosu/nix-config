{
  config,
  pkgs,
  username,
  ...
}: {
  # Add darwin prefs/configs
  programs.zsh.enable = true;
  environment.shells = [pkgs.bash pkgs.zsh];
  environment.systemPackages = [
    pkgs.coreutils
    pkgs.spotify
    pkgs.slack
    pkgs.rectangle
  ];
  environment.systemPath = ["/opt/homebrew/bin"];

  system.keyboard = {
    enableKeyMapping = true;
  };

  fonts.packages = [
    pkgs.powerline
  ];

  security.pam.services.sudo_local.touchIdAuth = true;

  system.primaryUser = username;
  system.defaults.finder.AppleShowAllExtensions = true;
  system.defaults.finder._FXShowPosixPathInTitle = true;
  system.defaults.dock.autohide = true;
  system.defaults.dock.show-recents = false;
  system.defaults.dock.magnification = true;
  system.defaults.dock.tilesize = 24;
  system.defaults.dock.largesize = 32;
  system.defaults.dock.persistent-apps = [
    "/Users/${username}/Applications/Home Manager Apps/Brave Browser.app"
    "/Applications/Nix Apps/Spotify.app"
    "/Applications/Sublime Text.app"
    "/Users/${username}/Applications/Home Manager Apps/Zed.app"
    "/Applications/Nix Apps/Slack.app"
    "/Users/${username}/Applications/Home Manager Apps/Alacritty.app"
  ];
  system.defaults.NSGlobalDomain.InitialKeyRepeat = 15;
  system.defaults.NSGlobalDomain.KeyRepeat = 2;
  system.defaults.NSGlobalDomain."com.apple.swipescrolldirection" = false;

  # Spotlight indexing on the data volume can end up switched off (a stray
  # `mdutil -i off`, a Spotlight Privacy entry, or a migration). When it is,
  # nothing under /Applications or ~/Applications is searchable -- including
  # the mac-app-util trampolines that make Home Manager apps visible at all.
  # Re-assert it here; `mdutil -i on` is a no-op when already enabled.
  system.activationScripts.postActivation.text = ''
    if ! /usr/bin/mdutil -s /System/Volumes/Data | grep -q "Indexing enabled"; then
      echo "enabling Spotlight indexing on /System/Volumes/Data..." >&2
      /usr/bin/mdutil -i on /System/Volumes/Data || true
    fi
  '';

  ### DO NOT MODIFY, for backwards compatibility
  system.stateVersion = 6;

  homebrew = {
    enable = true;
    #caskArgs.no_quarantine = true;
    global.brewfile = true;
    masApps = {};

    # nix-homebrew owns the taps (mutableTaps = false), so nix-darwin's
    # generated Brewfile listed none. `brew bundle`'s cleanup phase then read
    # homebrew/cask as an unwanted tap and untapped it -- and because
    # nix-homebrew sets HOMEBREW_NO_INSTALL_FROM_API=1, `brew untap` uninstalls
    # every cask from the tap first. Net effect: each activation installed
    # sublime-text and then removed it again. Listing the taps here keeps them.
    taps = builtins.attrNames config.nix-homebrew.taps;
    brews = [
      "vault-cli"
    ];
    casks = [
      "sublime-text"
    ];
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;
    onActivation.cleanup = "zap";
  };
}
