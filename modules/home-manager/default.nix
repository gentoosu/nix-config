{
  pkgs,
  pwnvim,
  username,
  ...
}: let
  nutanix-mcp = pkgs.callPackage ./packages/nutanix-mcp.nix {};
in {
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

  # Shared MCP server definitions. Declared here rather than under
  # programs.claude-code.mcpServers because only this module applies the
  # `.file` secret transform (see HOMEASSISTANT_TOKEN below); claude-code's
  # own mcpServers option would emit the file ref as a literal JSON object.
  programs.mcp = {
    enable = true;

    servers = {
      context7 = {
        type = "stdio";
        command = "npx";
        args = ["-y" "@upstash/context7-mcp@latest"];
      };

      ha-mcp = {
        type = "stdio";
        command = "uvx";
        args = ["ha-mcp"];
        env = {
          HOMEASSISTANT_URL = "https://hass.thehersh.net";
          # Read from disk at launch so the token never enters the Nix store
          HOMEASSISTANT_TOKEN.file = "/Users/${username}/.secrets/ha-token";
        };
      };

      # Built from Nutanix's git source, not PyPI — see packages/nutanix-mcp.nix.
      # FIXME: PC_HOST/PC_USERNAME are placeholders; set to your Prism Central.
      nutanix = {
        type = "stdio";
        command = "${nutanix-mcp}/bin/nutanix-mcp";
        args = ["serve-stdio"];
        env = {
          PC_HOST = "pc.example.lab";
          PC_PORT = "9440";
          PC_USERNAME = "admin";
          PC_PASSWORD.file = "/Users/${username}/.secrets/nutanix-pc-password";
          # true only if Prism Central uses a self-signed certificate
          PC_INSECURE = "false";
          # Writable: the server caches downloaded API YAMLs here
          ARTIFACTS_DIR = "/Users/${username}/.local/share/nutanix-mcp/artifacts";
          # Set false to allow this server to mutate your Nutanix environment
          READ_ONLY_MODE = "true";
        };
      };

      # Drop --read-only to allow cluster mutations
      kubernetes-mcp-server = {
        type = "stdio";
        command = "npx";
        args = ["-y" "kubernetes-mcp-server@latest" "--read-only"];
        env = {
          KUBECONFIG = "/Users/${username}/.kube/config";
        };
      };
    };
  };

  programs.claude-code = {
    enable = true;
    package = pkgs.claude-code; # from the nix-claude-code overlay, not nixpkgs

    # Off by default: without this, programs.mcp.servers above never reach
    # Claude Code (they'd only write ~/.config/mcp/mcp.json)
    enableMcpIntegration = true;

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
        # Bundles Datadog's MCP server and authenticates over OAuth, so no
        # API/app keys are needed here. Run /ddsetup once to log in.
        "datadog@claude-plugins-official" = true;
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
