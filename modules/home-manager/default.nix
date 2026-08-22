{
  pkgs,
  pwnvim,
  username,
  ...
}: {
  # Specify home-manager configs
  # DO NOT CHANGE version
  home.stateVersion = "25.05";
  home.packages = [
    pkgs.ansible
    pkgs.argocd
    pkgs.awscli2
    pkgs.azure-cli
    # claude-code is installed via programs.claude-code below
    pkgs.cloudflared
    pkgs.cookiecutter
    pkgs.curl
    pkgs.docker
    pkgs.dos2unix
    pkgs.fzf
    pkgs.git
    pkgs.gnutar
    pkgs.google-chrome
    pkgs.google-cloud-sdk
    pkgs.htop
    pkgs.iftop
    pkgs.iperf3
    pkgs.jq
    pkgs.krew
    pkgs.kubecolor
    pkgs.kubectl
    # pkgs.kubectl-access-matrix  ### Doesn't exist in nix packages
    pkgs.kubectl-ktop
    pkgs.kubectl-neat
    pkgs.kubectl-node-shell
    # pkgs.kubectl-resource-capacity ### Doesn't exist in nix packages
    # pkgs.kubectl-score ### Doesn't exist in nix packages
    # pkgs.kubectl-sniff ### Doesn't exist in nix packages
    # pkgs.kubectl-stern ### Doesn't exist in nix packages
    pkgs.kubectx
    # pkgs.kubens
    pkgs.kubernetes-helm
    pkgs.kubie
    pkgs.kustomize
    pkgs.localstack
    pkgs.meslo-lgs-nf
    pkgs.nmap
    pkgs.opentofu
    pkgs.postgresql
    #pkgs.rectangle
    pkgs.ripgrep
    pkgs.step-cli
    #pkgs.strace
    #pkgs.terraform-local
    pkgs.terragrunt
    pkgs.tfk8s
    pkgs.tree
    pkgs.uv
    # pkgs.vault  ### builds from source
    pkgs.watch
    pkgs.yamllint
    pkgs.yq
    pwnvim.packages."aarch64-darwin".default
  ];

  home.homeDirectory = "/Users/${username}";

  home.keyboard = {
    layout = "us";
    variant = "colemak";
  };

  home.sessionVariables = {
    PAGER = "less";
    EDITOR = "vim";
  };

  programs.bat = {
    enable = true;
    config.theme = "TwoDark";
  };

  programs.claude-code = {
    enable = true;
    package = pkgs.claude-code; # from the claude-code-nix overlay, not nixpkgs

    # Declared here, fetched natively by Claude Code: these keys land in
    # ~/.claude/settings.json, and Claude Code itself downloads/updates the
    # plugin content through its marketplace machinery.
    # NOTE: settings.json becomes a read-only symlink, so user-scope
    # /plugin installs won't stick — add plugins here instead.
    settings = {
      # Ported from the pre-existing hand-written ~/.claude/settings.json
      model = "claude-fable-5[1m]";
      tui = "fullscreen";

      extraKnownMarketplaces = {
        claude-community = {
          source = {
            source = "github";
            repo = "anthropics/claude-plugins-community";
          };
        };
      };
      enabledPlugins = {
        "superpowers@claude-plugins-official" = true;
      };
    };
  };

  programs.chromium = {
    enable = true;
    package = pkgs.brave;
    extensions = [
      {id = "nngceckbapebfimnlniiiahkandclblb";} #Bitwarden
    ];
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.git.enable = true;

  programs.alacritty = {
    enable = true;
    theme = "solarized_dark";
    settings = {
      font = {
        size = 14;
      };
    };
  };

  programs.zsh = {
    enable = true;
    history.size = 999999;
    history.extended = true;
    history.ignoreAllDups = true;
    enableCompletion = true;
    oh-my-zsh.enable = true;
    oh-my-zsh.theme = "agnoster";
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      ls = "ls --color=auto -F";
      nixswitch = "sudo ./result/sw/bin/darwin-rebuild switch --flake ~/git/nix-config/.#";
      nixup = "pushd ~/git/nix-config; nix flake update; nixswitch; popd";
    };
    initContent = ''
      prompt_context() {}
      setopt PROMPT_SUBST
      export PATH="$HOME/.local/bin:$PATH"
      export PROMPT='$(kube_ps1) '$PROMPT
    '';
    oh-my-zsh.plugins = [
      "git"
      "helm"
      "kubectl"
      "kubectx"
      "sudo"
      "brew"
      "common-aliases"
      "fzf"
      "vscode"
      "kube-ps1"
    ];
  };

  # programs.vscode = {
  #   enable = true;
  #   profiles.default.extensions = with pkgs.vscode-extensions; [
  #     bbenoist.nix
  #     brettm12345.nixfmt-vscode
  #     eamodio.gitlens
  #     hashicorp.terraform
  #     ms-python.vscode-pylance
  #     ms-python.python
  #     hashicorp.hcl
  #     hashicorp.terraform
  #     wholroyd.jinja
  #     redhat.vscode-yaml
  #     ms-kubernetes-tools.vscode-kubernetes-tools
  #   ];
  # };

  programs.zed-editor = import ../../modules/darwin/programs/zed-editor {
    inherit pkgs;
  };
}
