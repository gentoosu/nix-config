{
  pkgs,
  pwnvim,
  ...
}: {
  #Specify home-manager configs
  #DO NOT CHANGE version
  home.stateVersion = "25.05";
  home.packages = [
    pkgs.ansible
    pkgs.awscli
    pkgs.curl
    pkgs.docker
    pkgs.dos2unix
    pkgs.git
    pkgs.google-cloud-sdk
    pkgs.kubernetes-helm
    pkgs.htop
    pkgs.iftop
    pkgs.iperf3
    pkgs.jq
    pkgs.kubectl
    pkgs.kubectx
    pkgs.kustomize
    pkgs.nmap
    #    pkgs.nodejs_24
    pkgs.ripgrep
    pkgs.terraform
    pkgs.tree
    pkgs.watch
    pkgs.yq
    pwnvim.packages."x86_64-darwin".default
  ];

  home.homeDirectory = "/Users/gentoosu";

  home.keyboard = {
    layout = "us";
    variant = "colemak";
  };

  home.sessionVariables = {
    PAGER = "less";
    EDITOR = "vmim";
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
    ];
  };

  programs.vscode = {
    enable = true;
    profiles.default.extensions = with pkgs.vscode-extensions; [
      bbenoist.nix
      brettm12345.nixfmt-vscode
      eamodio.gitlens
      hashicorp.terraform
      ms-python.vscode-pylance
      ms-python.python
      hashicorp.hcl
      hashicorp.terraform
      wholroyd.jinja
      redhat.vscode-yaml
      ms-kubernetes-tools.vscode-kubernetes-tools
    ];
  };

#   programs.zed-editor = import ./modules/darwin/programs/zed-editor {
#     inherit pkgs;
#   };
}

