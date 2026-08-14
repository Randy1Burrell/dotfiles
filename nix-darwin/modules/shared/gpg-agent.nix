{ lib, pkgs, ... }:

let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
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
    defaultCacheTtl = 300;
    defaultCacheTtlSsh = 300;
    maxCacheTtl = 1200;
    maxCacheTtlSsh = 1200;
  } // lib.optionalAttrs isDarwin {
    pinentry.package = pkgs.pinentry_mac;
  };

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
