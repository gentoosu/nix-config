# agenix secret delivery for the MCP servers declared in ./default.nix.
#
# Uses agenix's *home-manager* module rather than its nix-darwin one. That is
# deliberate: the darwin module has no launchd unit, so its /run/agenix ramdisk
# disappears on reboot and stays gone until the next `darwin-rebuild switch`.
# The home-manager module ships a RunAtLoad launchd agent, so secrets are
# re-decrypted at login. These are user-scoped secrets anyway.
#
# Encrypted inputs live in the private nix-secrets repo; the recipient rules
# used to produce them live there too, in its own secrets.nix.
{
  agenix,
  nix-secrets,
  pkgs,
  username,
  ...
}: let
  # Stable paths the MCP wrapper scripts read at launch. These are symlinks
  # into the per-user temp dir (see the `path` note below), not real files.
  secretsDir = "/Users/${username}/.secrets";
in {
  imports = [agenix.homeManagerModules.default];

  # The CLI used to create, edit and rekey the *.age files. Run it from inside
  # the nix-secrets clone, where its ./secrets.nix rules file lives.
  home.packages = [agenix.packages.${pkgs.stdenv.hostPlatform.system}.default];

  # Passphrase-less, so the launchd agent can decrypt at login unattended.
  # Adding a machine means adding its pubkey to nix-secrets/secrets.nix.
  age.identityPaths = ["/Users/${username}/.ssh/id_ed25519"];

  # `path` is set explicitly for every secret. Left at its default, agenix's
  # darwin secretsDir is "$(getconf DARWIN_USER_TEMP_DIR)/agenix" -- a literal
  # shell substitution, which is fine inside agenix's own activation script but
  # unusable as a static path in mcp.json. Pointing `path` here instead gives a
  # stable symlink whose target is still the per-user temp dir, so the
  # decrypted plaintext is wiped on reboot and never lands in the Nix store.
  age.secrets = {
    ha-token = {
      file = "${nix-secrets}/ha-token.age";
      path = "${secretsDir}/ha-token";
    };

    context7-api-key = {
      file = "${nix-secrets}/context7-api-key.age";
      path = "${secretsDir}/context7-api-key";
    };

    nutanix-pc-host = {
      file = "${nix-secrets}/nutanix-pc-host.age";
      path = "${secretsDir}/nutanix-pc-host";
    };

    nutanix-pc-username = {
      file = "${nix-secrets}/nutanix-pc-username.age";
      path = "${secretsDir}/nutanix-pc-username";
    };

    nutanix-pc-password = {
      file = "${nix-secrets}/nutanix-pc-password.age";
      path = "${secretsDir}/nutanix-pc-password";
    };
  };
}
