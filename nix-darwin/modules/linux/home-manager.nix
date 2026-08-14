{ config, lib, pkgs, user, ... }:

let
  sharedFiles = import ../shared/files.nix {
    inherit pkgs;
    githubPublicKeySource = config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/.ssh/id_ed25519.pub";
  };
in
{
  imports = [
    ./secrets.nix
    ../shared/emacs-repository.nix
    ../shared/gpg-agent.nix
  ];

  # This is the Home Manager compatibility layer for Ubuntu and other
  # non-NixOS Linux distributions.
  targets.genericLinux.enable = true;

  home = {
    username = user;
    homeDirectory = "/home/${user}";
    stateVersion = "23.11";
    enableNixpkgsReleaseCheck = false;
    packages = pkgs.callPackage ../shared/packages.nix { };
    file = sharedFiles;
    sessionVariables.EDITOR = "${pkgs.emacs}/bin/emacsclient -c";
  };

  programs = import ../shared/home-manager.nix {
    inherit config lib pkgs;
  };

  fonts.fontconfig.enable = true;
  xdg.enable = true;

  gtk = {
    enable = true;
    gtk4.theme = config.gtk.theme;
    iconTheme = {
      name = "Adwaita-dark";
      package = pkgs.adwaita-icon-theme;
    };
    theme = {
      name = "Adwaita-dark";
      package = pkgs.adwaita-icon-theme;
    };
  };

  # Reload changed user services during activation without managing Ubuntu's
  # system-level services or desktop session.
  systemd.user.startServices = "sd-switch";
  services.udiskie.enable = true;
}
