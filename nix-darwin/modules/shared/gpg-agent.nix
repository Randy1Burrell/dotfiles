{ lib, pkgs, ... }:

let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  # Keep an actively used PIN/passphrase available for four hours, but never
  # beyond eight hours from its initial entry. Agent restart/logout clears it.
  defaultCacheSeconds = 4 * 60 * 60;
  maxCacheSeconds = 8 * 60 * 60;
  publishSshSocket = pkgs.writeShellScript "publish-gpg-ssh-socket" ''
    set -eu

    ssh_socket="$(${pkgs.gnupg}/bin/gpgconf --list-dirs agent-ssh-socket)"
    /bin/launchctl setenv SSH_AUTH_SOCK "$ssh_socket"
  '';
in
{
  programs.gpg = {
    enable = true;
    package = pkgs.gnupg;
    settings.auto-key-retrieve = true;
  };

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    # A terminal Pinentry works on Ubuntu desktops, virtual consoles, and
    # headless Linux hosts. macOS keeps its native graphical Pinentry.
    pinentry.package = if isDarwin then pkgs.pinentry_mac else pkgs.pinentry-curses;
    defaultCacheTtl = defaultCacheSeconds;
    defaultCacheTtlSsh = defaultCacheSeconds;
    maxCacheTtl = maxCacheSeconds;
    maxCacheTtlSsh = maxCacheSeconds;
  };

  # Apply changed TTLs immediately instead of waiting for the next login. A
  # reload intentionally clears any cache created under the previous policy.
  home.activation.reloadGpgAgentConfiguration = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    $DRY_RUN_CMD ${pkgs.gnupg}/bin/gpgconf --reload gpg-agent >/dev/null 2>&1 || true
  '';

  # Shell integrations set SSH_AUTH_SOCK at runtime. On macOS, publish the
  # same value to launchd so applications started outside a shell inherit it.
  launchd.agents.gpg-agent-environment = lib.mkIf isDarwin {
    enable = true;
    config = {
      ProgramArguments = [ (toString publishSshSocket) ];
      ProcessType = "Background";
      RunAtLoad = true;
    };
  };
}
