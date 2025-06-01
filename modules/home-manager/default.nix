{pkgs, ...}: {
#Specify home-manager configs
#DO NOT CHANGE version
home.stateVersion = "25.05";
home.packages = [
    pkgs.ansible
    pkgs.awscli
    pkgs.curl
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
    pkgs.ripgrep
    pkgs.terraform
    pkgs.tree
    pkgs.watch
    pkgs.yq
    inputs.pwnvm.packages."x86_64-darwin".default
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

programs.fzf = {
    enable = true;
    enableZshIntegration = true;
};

programs.git.enable = true;

programs.zsh = {
    enable = true;
    enableCompletion = true;
    oh-my-zsh.enable = true;
    oh-my-zsh.theme = "agnoster";
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {ls = "ls --color=auto -F";};
    oh-my-zsh.plugins = ["git" "helm" "kubectl" "kubectx" "sudo" "brew" "common-aliases" "fzf" "vscode"];
};

#programs.homebrew.iterm2.theme = "Solarized Dark";

programs.vscode = {
    enable = true;
    extensions = with pkgs.vscode-extensions; [
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
}