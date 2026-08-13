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
    #pkgs.claude-code
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
    pkgs.kubernetes-helm
    pkgs.htop
    pkgs.iftop
    pkgs.iperf3
    pkgs.jq
    pkgs.meslo-lgs-nf
    pkgs.postgresql
    pkgs.krew
    pkgs.kubecolor
    pkgs.kubectl
    pkgs.kubectl-ktop
    pkgs.kubectl-neat
    # pkgs.kubectl-access-matrix  ### Doesn't exist in nix packages
    pkgs.kubectl-node-shell
    # pkgs.kubectl-sniff ### Doesn't exist in nix packages
    # pkgs.kubectl-resource-capacity ### Doesn't exist in nix packages
    # pkgs.kubectl-score ### Doesn't exist in nix packages
    # pkgs.kubectl-stern ### Doesn't exist in nix packages
    pkgs.kubectx
    # pkgs.kubens
    pkgs.kubie
    pkgs.kustomize
    pkgs.localstack
    pkgs.nmap
    #pkgs.rectangle
    pkgs.ripgrep
    #pkgs.strace
    pkgs.opentofu
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
