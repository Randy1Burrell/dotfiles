{ config, pkgs, lib, home-manager, homeDirectory, githubUser, user, ... }:

let
  # Define the content of your file as a derivation
  myEmacsLauncher = pkgs.writeScript "emacs-launcher.command" ''
    #!/bin/sh
    emacsclient -c -n &
  '';
  additionalFiles = import ./files.nix { inherit user config pkgs; };
in
{
  imports = [
    ./dock
  ];

  # It me
  users.users.${user} = {
    name = "${user}";
    home = homeDirectory;
    isHidden = false;
    shell = pkgs.zsh;
  };

  homebrew = {
    enable = true;
    enableZshIntegration = true;
    # Homebrew 6 requires the explicit `install` subcommand before accepting
    # --force-cleanup. Keep formula and cask cleanup non-interactive, but never
    # remove Mac App Store applications: `mas list` cannot tell whether an app
    # was installed by this configuration, the App Store UI, or an MDM.
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "none";
      extraEnv.HOMEBREW_BUNDLE_CLEANUP_NO_MAS = "1";
      extraFlags = [ "install" "--force-cleanup" ];
    };
    casks = pkgs.callPackage ./casks.nix { };
    brews = pkgs.callPackage ./brews.nix { };

    # These app IDs are from using the mas CLI app
    # mas = mac app store
    # https://github.com/mas-cli/mas
    #
    # $ nix shell nixpkgs#mas
    # $ mas search <app name>
    #
    # Apps already declared in casks.nix must not also be listed here. Homebrew
    # Bundle tracks casks and Mac App Store receipts separately and would try to
    # install a second copy of the same application.
    masApps = {
      "1Password for Safari" = 1569813296;
      "Docs for Developers" = 1411232591;
      "GarageBand" = 682658836;
      "Grammarly for Safari" = 1462114288;
      "Keynote" = 409183694;
      "LG Screen Manager" = 1142051783;
      "LimeChat" = 414030210;
      "Microsoft Remote Desktop" = 1295203466;
      "Numbers" = 409203825;
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
    verbose = true;
    users.${user} = { pkgs, config, lib, ... }:
      let
        sharedFiles = import ../shared/files.nix { };
      in
      {
        imports = [
          ../shared/emacs-repository.nix
          ../shared/gpg-agent.nix
        ];

        home = {
          # This is an internal compatibility configuration for home-manager,
          # only to be changed under very careful conditions.
          sessionVariables = {
            EDITOR = "${pkgs.emacs}/bin/emacsclient -t";
            GITHUB_USER = githubUser;
          };

          enableNixpkgsReleaseCheck = false;
          file = sharedFiles // additionalFiles;
          packages = pkgs.callPackage ./packages.nix { };

          stateVersion = "23.11";
        };

        programs = { } // import ../shared/home-manager.nix {
          inherit config githubUser pkgs lib;
        };

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
        # { path = "/Applications/Launchpad.app/"; }
        { path = "/Applications/Mission Control.app/"; }
        { path = "/Applications/Setapp/Spark\ Mail.app/"; }
        { path = "/Applications/Setapp/Noteplan.app/"; }
        { path = "/System/Cryptexes/App/System/Applications/Safari.app/"; }
        { path = "/Applications/Google\ Chrome.app/"; }
        { path = "/Applications/Slack.app/"; }
        { path = "${pkgs.alacritty}/Applications/Alacritty.app/"; }
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
