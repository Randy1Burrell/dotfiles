{
  description = "Randy's system flake";

  inputs = {
    nixpkgs = {
      # A current, tested release provides the same stock Emacs on macOS and
      # Linux without depending on the bleeding-edge Emacs overlay.
      url = "github:NixOS/nixpkgs/nixos-26.05";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix";
      # Keep agenix's CLI on the same supported package set as the system.
      # Its older independent lock supplied age 1.1.1, whose Darwin binary is
      # rejected by current macOS releases for lacking an LC_UUID command.
      inputs.nixpkgs.follows = "nixpkgs";
    };
    darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew = {
      url = "github:zhaofengli-wip/nix-homebrew";
    };
    brew = {
      url = "github:homebrew/brew";
      flake = false;
    };
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    secrets = {
      url = "git+ssh://git@github.com/randy1burrell/secrets.git";
      flake = false;
    };
  };

  outputs = { self, darwin, nix-homebrew, brew, homebrew-core, homebrew-cask, home-manager, nixpkgs, disko, agenix, secrets } @inputs:
    let
      user = "randyburrell";
      # setup supplies host identities during impure macOS and Linux
      # evaluations. Pure checks retain the repository owner's account.
      darwinUser =
        let detectedUser = builtins.getEnv "DOTFILES_DARWIN_USER";
        in if detectedUser != "" then detectedUser else user;
      darwinHome =
        let detectedHome = builtins.getEnv "DOTFILES_DARWIN_HOME";
        in if detectedHome != "" then detectedHome else "/Users/${darwinUser}";
      genericLinuxUser =
        let detectedUser = builtins.getEnv "DOTFILES_LINUX_USER";
        in if detectedUser != "" then detectedUser else user;
      genericLinuxHome =
        let detectedHome = builtins.getEnv "DOTFILES_LINUX_HOME";
        in if detectedHome != "" then detectedHome else "/home/${genericLinuxUser}";
      nixosUser =
        let detectedUser = builtins.getEnv "DOTFILES_NIXOS_USER";
        in if detectedUser != "" then detectedUser else user;
      nixosHome =
        let detectedHome = builtins.getEnv "DOTFILES_NIXOS_HOME";
        in if detectedHome != "" then detectedHome else "/home/${nixosUser}";
      nixosHostName =
        let detectedHostName = builtins.getEnv "DOTFILES_NIXOS_HOSTNAME";
        in if detectedHostName != "" then detectedHostName else "nixos";
      nixosDiskDevice =
        let detectedDisk = builtins.getEnv "DOTFILES_NIXOS_DISK";
        in if detectedDisk != "" then detectedDisk else "/dev/vda";
      githubUser =
        let detectedUser = builtins.getEnv "DOTFILES_GITHUB_USER";
        in if detectedUser != "" then detectedUser else "randy1burrell";
      linuxSystems = [ "x86_64-linux" "aarch64-linux" ];
      darwinSystems = [ "aarch64-darwin" "x86_64-darwin" ];
      ubuntuAptPackages = import ./modules/linux/apt-packages.nix;
      ubuntuSnaps = import ./modules/linux/snaps.nix;
      ubuntuSnapsFor = system: builtins.filter
        (snap: builtins.elem system (snap.systems or linuxSystems))
        ubuntuSnaps;
      ubuntuSnapCasksFor = system: map (snap: snap.cask)
        (builtins.filter (snap: snap ? cask) (ubuntuSnapsFor system));
      # The macOS Homebrew module remains the single source of truth for
      # formulae. Linuxbrew consumes every portable entry from that list, but
      # leaves Snap-backed GUI applications to Ubuntu's native integration.
      # GnuPG, GPGME, and Pinentry stay Nix-managed on Linux so Home Manager's
      # socket-activated daemons cannot be mixed with Linuxbrew clients from a
      # different release.
      linuxbrewFormulae = nixpkgs.lib.unique (builtins.filter
        (formula: !(builtins.elem formula [
          "gnupg"
          "gpgme"
          "mas"
          "pinentry"
          "pinentry-mac"
        ]))
        (import ./modules/darwin/brews.nix { }));
      linuxbrewCaskCandidates = system: nixpkgs.lib.unique (builtins.filter
        (cask: !(builtins.elem cask (ubuntuSnapCasksFor system)))
        (import ./modules/darwin/casks.nix { }));
      overlays =
        let path = ./overlays; in
        map (name: import (path + ("/" + name)))
          (builtins.filter
            (name:
              builtins.match ".*\\.nix" name != null ||
              builtins.pathExists (path + ("/" + name + "/default.nix")))
            (builtins.attrNames (builtins.readDir path)));
      mkLinuxPkgs = system: import nixpkgs {
        inherit system overlays;
        config = {
          allowUnfree = true;
          allowBroken = true;
          allowInsecure = false;
          allowUnsupportedSystem = true;
        };
      };
      mkGenericLinuxHome = system: home-manager.lib.homeManagerConfiguration {
        pkgs = mkLinuxPkgs system;
        extraSpecialArgs = inputs // {
          user = genericLinuxUser;
          homeDirectory = genericLinuxHome;
          inherit githubUser;
        };
        modules = [
          agenix.homeManagerModules.default
          ./modules/linux/home-manager.nix
        ];
      };
      mkLinuxbrewBrewfile = system:
        let pkgs = mkLinuxPkgs system;
        in pkgs.writeText "Brewfile" ''
          # Generated from modules/darwin/brews.nix. setup appends casks from
          # the macOS list when Homebrew reports native Linux support.
          ${nixpkgs.lib.concatMapStringsSep "\n"
            (formula: "brew ${builtins.toJSON formula}")
            linuxbrewFormulae}
        '';
      mkLinuxbrewCaskCandidates = system:
        let pkgs = mkLinuxPkgs system;
        in pkgs.writeText "linuxbrew-cask-candidates" ''
          ${nixpkgs.lib.concatStringsSep "\n" (linuxbrewCaskCandidates system)}
        '';
      mkUbuntuAptPackages = system:
        let pkgs = mkLinuxPkgs system;
        in pkgs.writeText "ubuntu-apt-packages"
          "${nixpkgs.lib.concatStringsSep "\n" ubuntuAptPackages}\n";
      mkUbuntuSnapPackages = system:
        let
          pkgs = mkLinuxPkgs system;
          renderSnap = snap: nixpkgs.lib.concatStringsSep "\t" [
            snap.name
            (snap.channel or "latest/stable")
            (if (snap.classic or false) then "classic" else "strict")
          ];
        in pkgs.writeText "ubuntu-snap-packages"
          "${nixpkgs.lib.concatMapStringsSep "\n" renderSnap (ubuntuSnapsFor system)}\n";
      forAllSystems = f: nixpkgs.lib.genAttrs (linuxSystems ++ darwinSystems) f;
      devShell = system:
        let pkgs = nixpkgs.legacyPackages.${system}; in {
          default = with pkgs; mkShell {
            nativeBuildInputs = with pkgs; [ bashInteractive git age age-plugin-yubikey ];
            shellHook = with pkgs; ''
              export EDITOR=emacsclient -c
            '';
          };
        };
      mkApp = scriptName: system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          # Linux helpers are architecture-neutral and share one maintained
          # implementation. This also keeps aarch64-linux outputs from
          # referring to a directory that does not exist.
          scriptSystem = if builtins.elem system linuxSystems then "x86_64-linux" else system;
          sshPackage = if pkgs.stdenv.hostPlatform.isLinux then pkgs.openssh_gssapi else pkgs.openssh;
          runtimePackages = with pkgs; [
            bashInteractive
            coreutils
            findutils
            gawk
            git
            gnugrep
            gnupg
          ] ++ [ sshPackage ] ++ nixpkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [
            curl
            iproute2
            unzip
            util-linux
          ];
        in
        {
          type = "app";
          program = "${(pkgs.writeScriptBin scriptName ''
            #!/usr/bin/env bash
            PATH=${nixpkgs.lib.makeBinPath runtimePackages}:$PATH
            echo "Running ${scriptName} for ${system}"
            exec ${self}/apps/${scriptSystem}/${scriptName} "$@"
          '')}/bin/${scriptName}";
          meta.description = "Run the dotfiles ${scriptName} helper";
        };
      mkLinuxApps = system: {
        "apply" = mkApp "apply" system;
        "build-switch" = mkApp "build-switch" system;
        "copy-keys" = mkApp "copy-keys" system;
        "create-keys" = mkApp "create-keys" system;
        "check-keys" = mkApp "check-keys" system;
        "gpg" = mkApp "gpg" system;
        "clean" = mkApp "clean" system;
      };
      mkDarwinApps = system: {
        "apply" = mkApp "apply" system;
        "build" = mkApp "build" system;
        "build-switch" = mkApp "build-switch" system;
        "clean" = mkApp "clean" system;
        "copy-keys" = mkApp "copy-keys" system;
        "create-keys" = mkApp "create-keys" system;
        "check-keys" = mkApp "check-keys" system;
        "gpg" = mkApp "gpg" system;
        "rollback" = mkApp "rollback" system;
      };
      mkDarwinSystem = system: nixbldGid:
        darwin.lib.darwinSystem {
          inherit system;
          specialArgs = inputs // {
            user = darwinUser;
            homeDirectory = darwinHome;
            inherit githubUser;
          };
          modules = [
            {
              nixpkgs.hostPlatform = system;
              ids.gids.nixbld = nixbldGid;
            }
            home-manager.darwinModules.home-manager
            # nix-homebrew.darwinModules.nix-homebrew
            # {
            #   nix-homebrew = {
            #     inherit user;
            #     enable = true;
            #     enableRosetta = true;
            #     taps = {
            #       "homebrew/core" = homebrew-core;
            #       "homebrew/cask" = homebrew-cask;
            #       "homebrew/bundle" = brew;
            #     };
            #     mutableTaps = false;
            #     autoMigrate = false;
            #   };
            # }
            ./hosts/darwin
          ];
        };
    in
    {
      devShells = forAllSystems devShell;
      apps = nixpkgs.lib.genAttrs linuxSystems mkLinuxApps // nixpkgs.lib.genAttrs darwinSystems mkDarwinApps;
      packages = nixpkgs.lib.genAttrs linuxSystems (system: {
        linuxbrew-brewfile = mkLinuxbrewBrewfile system;
        linuxbrew-cask-candidates = mkLinuxbrewCaskCandidates system;
        ubuntu-apt-packages = mkUbuntuAptPackages system;
        ubuntu-snap-packages = mkUbuntuSnapPackages system;
      });

      # Standalone Home Manager targets for Ubuntu and other non-NixOS Linux
      # distributions. NixOS continues to use the integrated module below.
      homeConfigurations = nixpkgs.lib.genAttrs linuxSystems mkGenericLinuxHome;

      # The upstream and Determinate installers have used different nixbld
      # group IDs on macOS. Keep both variants declarative; setup selects the
      # one matching the group that already exists on the machine.
      darwinConfigurations =
        nixpkgs.lib.genAttrs darwinSystems (system: mkDarwinSystem system 30000)
        // builtins.listToAttrs (map (system: {
          name = "${system}-gid350";
          value = mkDarwinSystem system 350;
        }) darwinSystems);

      nixosConfigurations = nixpkgs.lib.genAttrs linuxSystems (system: nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = inputs // {
          user = nixosUser;
          homeDirectory = nixosHome;
          inherit githubUser nixosDiskDevice nixosHostName;
        };
        modules = [
          disko.nixosModules.disko
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              backupFileExtension = "bk";
              extraSpecialArgs = {
                user = nixosUser;
                homeDirectory = nixosHome;
                inherit githubUser;
              };
              useGlobalPkgs = true;
              useUserPackages = true;
              users.${nixosUser} = import ./modules/nixos/home-manager.nix;
            };
          }
          ./hosts/nixos
        ];
      });
    };
}
