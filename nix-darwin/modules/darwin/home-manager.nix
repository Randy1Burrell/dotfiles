{ config, pkgs, lib, home-manager, ... }:

let
  user = "randyburrell";
  # Define the content of your file as a derivation
  myEmacsLauncher = pkgs.writeScript "emacs-launcher.command" ''
    #!/bin/sh
    emacsclient -c -n &
  '';
  sharedFiles = import ../shared/files.nix { inherit config pkgs; };
  additionalFiles = import ./files.nix { inherit user config pkgs; };
in
{
  imports = [
    ./dock
  ];

  # It me
  users.users.${user} = {
    name = "${user}";
    home = "/Users/${user}";
    isHidden = false;
    shell = pkgs.zsh;
  };

  homebrew = {
    enable = true;
    casks = pkgs.callPackage ./casks.nix { };
    brews = pkgs.callPackage ./brews.nix { };

    # These app IDs are from using the mas CLI app
    # mas = mac app store
    # https://github.com/mas-cli/mas
    #
    # $ nix shell nixpkgs#mas
    # $ mas search <app name>
    #
    masApps = {
      "1password" = 1333542190;
      "1Password for Safari" = 1569813296;
      "Docs for Developers" = 1411232591;
      "GarageBand" = 682658836;
      "Grammarly for Safari" = 1462114288;
      "Keynote" = 409183694;
      "LG Screen Manager" = 1142051783;
      "LimeChat" = 414030210;
      "Microsoft Remote Desktop" = 1295203466;
      "Numbers" = 409203825;
      "Slack" = 803453959;
      "Telegram" = 747648890;
      "WhatsApp" = 310633997;
      "Xcode" = 497799835;
      "Yubico Authenticator" = 1497506650;
      # "WireGuard" = 1451685025;
      # "Microsoft Word" = 462054704;
      # "Microsoft Excel" = 462058435;
      # "Microsoft PowerPoint" = 462062816;
      # "Microsoft Outlook" = 985367838;
      # "Microsoft OneNote" = 784801555;
      # "One Drive" = 823766827;
    };
  };

  # Enable home-manager
  home-manager = {
    backupFileExtension = "bk";
    useGlobalPkgs = true;
    useUserPackages = true;
    users.${user} = { pkgs, config, lib, ... }: {
      home = {
        # This is an internal compatibility configuration for home-manager,
        # only to be changed under very careful conditions.
        sessionVariables = {
          EDITOR = "${pkgs.emacs}/bin/emacsclient -c";
        };
        enableNixpkgsReleaseCheck = false;
        packages = pkgs.callPackage ./packages.nix { };

        stateVersion = "23.11";
      };

      programs = { } // import ../shared/home-manager.nix { inherit config pkgs lib; };

      # Marked broken Oct 20, 2022 check later to remove this
      # https://github.com/nix-community/home-manager/issues/3344
      manual.manpages.enable = false;
    };
  };

  # Fully declarative dock using the latest from Nix Store
  local = {
    dock = {
      enable = true;
      entries = [
        # { path = "/System/Applications/Messages.app/"; }
        { path = "/Applications/Mission Control.app/"; }
        { path = "/Applications/Launchpad.app/"; }
        { path = "/Applications/Setapp/Spark\ Mail.app/"; }
        { path = "/Applications/Setapp/Noteplan.app/"; }
        { path = "/System/Cryptexes/App/System/Applications/Safari.app/"; }
        { path = "/Applications/Google\ Chrome.app/"; }
        {
          path = "/Applications/Slack.app/";
        }
        {
          path = "${pkgs.alacritty}/Applications/Alacritty.app/";
        }
        {
          path = "${config.users.users.${user}.home}/.local/share/";
          section = "others";
          options = "--sort name --view grid --display folder";
        }
        {
          path = "${config.users.users.${user}.home}/downloads";
          section = "others";
          options = "--sort name --view grid --display stack";
        }
        {
          path = "/Applications/setapp";
          section = "others";
          options = "--sort name --view grid --display stack";
        }
      ];
    };
  };
}
