{ config, githubUser, homeDirectory, lib, pkgs, user, ... }:

let
  sharedFiles = import ../shared/files.nix { };
  sharedPrograms = import ../shared/home-manager.nix {
    inherit config githubUser lib pkgs;
  };
  emacsLauncher = pkgs.writeShellScript "emacs-launcher" ''
    exec ${pkgs.emacs}/bin/emacsclient -c -n -a "" "$@"
  '';
  emacsDesktopEntry = pkgs.makeDesktopItem {
    name = "emacs";
    desktopName = "Emacs";
    genericName = "Text Editor";
    comment = "Edit text and code with the managed Emacs daemon";
    exec = "${emacsLauncher} %F";
    icon = "${pkgs.emacs}/share/icons/hicolor/scalable/apps/emacs.svg";
    terminal = false;
    categories = [ "Development" "TextEditor" ];
    mimeTypes = [
      "text/plain"
      "text/x-c"
      "text/x-c++"
      "text/x-python"
    ];
  };
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
    sessionPath = [
      "/home/linuxbrew/.linuxbrew/bin"
      "/home/linuxbrew/.linuxbrew/sbin"
    ];
    sessionVariables = {
      EDITOR = "${pkgs.emacs}/bin/emacsclient -t";
      GITHUB_USER = githubUser;
    };
  };

  programs = sharedPrograms // {
    bash = sharedPrograms.bash // {
      enableCompletion = true;
      initExtra = lib.mkMerge [
        sharedPrograms.bash.initExtra
        (lib.mkAfter ''
          if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
            eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
            if [[ -r /home/linuxbrew/.linuxbrew/etc/profile.d/bash_completion.sh ]]; then
              source /home/linuxbrew/.linuxbrew/etc/profile.d/bash_completion.sh
            elif [[ -d /home/linuxbrew/.linuxbrew/etc/bash_completion.d ]]; then
              for completion in /home/linuxbrew/.linuxbrew/etc/bash_completion.d/*; do
                [[ -r "$completion" ]] && source "$completion"
              done
              unset completion
            fi
          fi
        '')
      ];
    };
    zsh = sharedPrograms.zsh // {
      envExtra = lib.mkMerge [
        sharedPrograms.zsh.envExtra
        (lib.mkAfter ''
          if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
            typeset -U fpath
            fpath=(/home/linuxbrew/.linuxbrew/share/zsh/site-functions $fpath)
            eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
          fi
        '')
      ];
    };
  };

  fonts.fontconfig.enable = true;
  xdg.enable = true;
  # Put the launcher directly in ~/.local/share/applications so GNOME's
  # overview can find Emacs even when it does not index the Nix profile.
  xdg.dataFile."applications/emacs.desktop".source =
    "${emacsDesktopEntry}/share/applications/emacs.desktop";
  home.activation.refreshDesktopDatabase = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    $DRY_RUN_CMD ${pkgs.desktop-file-utils}/bin/update-desktop-database \
      ${lib.escapeShellArg "${config.xdg.dataHome}/applications"}
  '';

  # Reload changed user services during activation without managing Ubuntu's
  # system-level services or desktop session.
  systemd.user.startServices = "sd-switch";
  services.udiskie.enable = true;
}
