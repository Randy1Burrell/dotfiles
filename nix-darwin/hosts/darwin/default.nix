{ self, agenix, config, pkgs, ... }:

let user = "randyburrell"; in

{

  imports = [
    ../../modules/darwin/secrets.nix
    ../../modules/darwin/home-manager.nix
    ../../modules/shared
    ../../modules/shared/cachix
    agenix.darwinModules.default
  ];

  services = {
    skhd = {
      enable = true;
      skhdConfig = "cmd + alt - e : emacsclient -c -n \n";
    };
  };

  # Auto upgrade nix package and the daemon service.
  # Setup user, packages, programs
  nix = {
    package = pkgs.nix;
    settings.trusted-users = [ "@admin" "${user}" ];

    gc = {
      automatic = true;
      interval = { Weekday = 0; Hour = 2; Minute = 0; };
      options = "--delete-older-than 30d";
    };

    # Turn this on to make command line easier
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  system.primaryUser = user;

  networking.applicationFirewall.enableStealthMode = true;

  # Home Manager initializes completion after removing Homebrew's
  # group-writable completion paths from fpath.
  programs.zsh = {
    enableGlobalCompInit = false;
    enableBashCompletion = false;
  };

  # Load configuration that is shared across systems
  environment = {
    systemPackages = with pkgs; [
      # emacs-unstable
      agenix.packages."${pkgs.stdenv.hostPlatform.system}".default
    ] ++ (import ../../modules/shared/packages.nix { inherit pkgs; });

    # Place global environment variables here
    variables = {
      JAVA_HOME = "${pkgs.zulu}";
    };
  };
  launchd.user.agents.emacs.path = [ config.environment.systemPath ];
  launchd.user.agents.emacs.serviceConfig = {
    KeepAlive = true;
    ProgramArguments = [
      "/bin/sh"
      "-c"
      "/bin/wait4path ${pkgs.emacs}/bin/emacs && exec ${pkgs.emacs}/bin/emacs --fg-daemon"
    ];
    StandardErrorPath = "/tmp/emacs.err.log";
    StandardOutPath = "/tmp/emacs.out.log";
  };

  system = {
    # Used for backwards compatibility, please read the changelog before changing.
    # $ darwin-rebuild changelog
    stateVersion = 4;

    # Turn off NIX_PATH warnings now that we're using flakes
    checks.verifyNixPath = false;

    # Set Git commit hash for darwin-version.
    configurationRevision = self.rev or self.dirtyRev or null;

    # nix-darwin 24.05 created this as a symlink into the Nix store. If that
    # generation has been garbage-collected, the dangling link prevents newer
    # nix-darwin releases from creating their managed applications directory.
    activationScripts.preActivation.text = ''
      nixAppsPath='/Applications/Nix Apps'

      if [[ -L "$nixAppsPath" && ! -e "$nixAppsPath" ]]; then
        oldNixAppsTarget="$(readlink "$nixAppsPath")"

        case "$oldNixAppsTarget" in
          /nix/store/*-system-applications/Applications)
            echo >&2 "removing stale nix-darwin applications link..."
            rm -- "$nixAppsPath"
            ;;
          *)
            printf >&2 'error: %s is an unrecognized dangling symlink to %s\n' \
              "$nixAppsPath" "$oldNixAppsTarget"
            exit 1
            ;;
        esac
      fi
    '';

    defaults = {
      NSGlobalDomain = {
        AppleShowAllExtensions = true;
        ApplePressAndHoldEnabled = false;

        # 120, 90, 60, 30, 12, 6, 2
        KeyRepeat = 6;

        # 120, 94, 68, 35, 25, 15
        InitialKeyRepeat = 15;

        "com.apple.mouse.tapBehavior" = 1;
        "com.apple.sound.beep.volume" = 0.35;
        "com.apple.springing.delay" = 0.35;
        "com.apple.springing.enabled" = true;
        "com.apple.sound.beep.feedback" = 0;
        "com.apple.keyboard.fnState" = true;
        "com.apple.swipescrolldirection" = false;
      };

      dock = {
        appswitcher-all-displays = true;
        autohide = false;
        enable-spring-load-actions-on-all-items = true;
        largesize = 56;
        launchanim = true;
        magnification = true;
        mineffect = "genie";
        minimize-to-application = true;
        mouse-over-hilite-stack = true;
        orientation = "bottom";
        show-recents = false;
        tilesize = 36;
      };

      finder = {
        _FXShowPosixPathInTitle = false;
        FXDefaultSearchScope = "SCcf";
        FXPreferredViewStyle = "clmv";
        QuitMenuItem = true;
        ShowPathbar = true;
        ShowStatusBar = true;
      };

      trackpad = {
        Clicking = true;
        TrackpadThreeFingerDrag = false;
        Dragging = true;
        TrackpadRightClick = true;
      };

      loginwindow = {
        GuestEnabled = false;
        LoginwindowText = "Grundy";
        SHOWFULLNAME = false;
        ShutDownDisabledWhileLoggedIn = true;
      };

      magicmouse.MouseButtonMode = "TwoButton";

      menuExtraClock = {
        IsAnalog = false;
        Show24Hour = true;
        ShowDate = 0;
        ShowDayOfMonth = true;
        ShowDayOfWeek = true;
        ShowSeconds = true;
      };
    };

    keyboard = {
      enableKeyMapping = true;
    };
  };
}
