{ config, homeDirectory, lib, pkgs, user, ... }:

let
  sharedFiles = import ../shared/files.nix { };
in
{
  imports = [
    ./secrets.nix
    ./macos-desktop.nix
    ../shared/emacs-repository.nix
    ../shared/gpg-agent.nix
  ];

  # This is the Home Manager compatibility layer for Ubuntu and other
  # non-NixOS Linux distributions.
  targets.genericLinux.enable = true;

  home = {
    username = user;
    inherit homeDirectory;
    stateVersion = "23.11";
    enableNixpkgsReleaseCheck = false;
    packages = pkgs.callPackage ../shared/packages.nix { };
    file = sharedFiles;
    sessionVariables.EDITOR = "${pkgs.emacs}/bin/emacsclient -t";
  };

  programs = import ../shared/home-manager.nix {
    inherit config lib pkgs;
  };

  fonts.fontconfig.enable = true;
  xdg.enable = true;

  # Reload changed user services during activation without managing Ubuntu's
  # system-level services or desktop session.
  systemd.user.startServices = "sd-switch";
  services.udiskie.enable = true;
}
