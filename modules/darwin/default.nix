{pkgs, ...}: {
    # Add darwin prefs/configs
    programs.zsh.enable = true;
    environment.shells = [pkgs.bash pkgs.zsh];
    #environment.loginShell = pkgs.zsh;
    environment.systemPackages = [
        pkgs.coreutils
        pkgs.spotify
        pkgs.slack
        #pkgs.sublime
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
    system.defaults.dock.autohide = true;
    system.defaults.dock.show-recents = false;
    system.defaults.dock.magnification = true;
    system.defaults.dock.tilesize = 24;
    system.defaults.dock.largesize = 32;
    system.defaults.dock.persistent-apps = [
        "/Users/gentoosu/Applications/Home Manager Apps/Brave Browser.app"
        "/Applications/Nix Apps/Spotify.app"
        "/Applications/Sublime Text.app"
        #"Users/gentoosu/Applications/Home Manager Apps/Visual Studio Code.app"
        "/Users/gentoosu/Applications/Home Manager Apps/Zed.app"
        "/Applications/Nix Apps/Slack.app"
        "/Users/gentoosu/Applications/Home Manager Apps/Alacritty.app"
        ];
    system.defaults.NSGlobalDomain.InitialKeyRepeat = 15;
    system.defaults.NSGlobalDomain.KeyRepeat = 2;
    system.defaults.NSGlobalDomain."com.apple.swipescrolldirection" = false;

    ### DO NOT MODIFY, for backwards compatibility
    system.stateVersion = 6;

    homebrew = {
        enable = true;
        caskArgs.no_quarantine = true;
        global.brewfile = true;
        masApps = {};
        casks = [
            "sublime-text"
        ];
        #taps = ["fujiapple852/trippy"];
        #brews = ["trippy"];
        onActivation.cleanup = "zap";
    };
}
