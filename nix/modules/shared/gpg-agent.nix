{ config, lib, pkgs, ... }:

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
    # Graphical Emacs has no controlling TTY, so a curses-only Pinentry fails
    # with "Inappropriate ioctl for device". The GTK build opens a desktop
    # dialog and is also built with curses/TTY fallbacks for headless sessions.
    # macOS keeps its native graphical Pinentry.
    pinentry.package = if isDarwin then pkgs.pinentry_mac else pkgs.pinentry-gtk2;
    defaultCacheTtl = defaultCacheSeconds;
    defaultCacheTtlSsh = defaultCacheSeconds;
    maxCacheTtl = maxCacheSeconds;
    maxCacheTtlSsh = maxCacheSeconds;
  };

  # Ubuntu ships user-level dirmngr socket units whose ExecStart points at the
  # distribution GnuPG.  Without an override, contacting the standard socket
  # can silently start /usr/bin/dirmngr alongside Home Manager's newer GnuPG
  # client.  Own this unit as well so every process in the suite has exactly
  # the same version and GNUPGHOME.
  systemd.user.services.dirmngr = lib.mkIf (!isDarwin) {
    Unit = {
      Description = "GnuPG network certificate management daemon";
      Documentation = "man:dirmngr(8)";
      Requires = "dirmngr.socket";
      After = "dirmngr.socket";
      RefuseManualStart = true;
    };
    Service = {
      ExecStart = "${pkgs.gnupg}/bin/dirmngr --supervised";
      ExecReload = "${pkgs.gnupg}/bin/gpgconf --reload dirmngr";
      Environment = [ "GNUPGHOME=${config.programs.gpg.homedir}" ];
    };
  };

  systemd.user.sockets.dirmngr = lib.mkIf (!isDarwin) {
    Unit = {
      Description = "GnuPG network certificate management daemon";
      Documentation = "man:dirmngr(8)";
    };
    Socket = {
      ListenStream = "%t/gnupg/S.dirmngr";
      Service = "dirmngr.service";
      SocketMode = "0600";
      DirectoryMode = "0700";
    };
    Install.WantedBy = [ "sockets.target" ];
  };

  # Apply changed TTLs immediately instead of waiting for the next login. A
  # reload intentionally clears any cache created under the previous policy.
  # Stop a daemon inherited from the host distribution or an older profile.
  # Home Manager's systemd reconciliation then starts the matching version on
  # Linux; the managed gpg client starts it lazily on macOS.
  home.activation.reloadGpgAgentConfiguration = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    $DRY_RUN_CMD ${pkgs.gnupg}/bin/gpgconf --kill dirmngr >/dev/null 2>&1 || true
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
