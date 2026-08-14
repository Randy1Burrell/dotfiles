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
      linuxSystems = [ "x86_64-linux" "aarch64-linux" ];
      darwinSystems = [ "aarch64-darwin" "x86_64-darwin" ];
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
        extraSpecialArgs = inputs // { inherit user; };
        modules = [
          agenix.homeManagerModules.default
          ./modules/linux/home-manager.nix
        ];
      };
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
          runtimePackages = with pkgs; [
            bashInteractive
            coreutils
            findutils
            gawk
            git
            gnugrep
            gnupg
            openssh
          ] ++ nixpkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [
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
            exec ${self}/apps/${system}/${scriptName} "$@"
          '')}/bin/${scriptName}";
        };
      mkLinuxApps = system: {
        "apply" = mkApp "apply" system;
        "build-switch" = mkApp "build-switch" system;
        "copy-keys" = mkApp "copy-keys" system;
        "create-keys" = mkApp "create-keys" system;
        "check-keys" = mkApp "check-keys" system;
        "gpg" = mkApp "gpg" system;
        "clean" = mkApp "clean" system;
        "install" = mkApp "install" system;
        "install-with-secrets" = mkApp "install-with-secrets" system;
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
    in
    {
      devShells = forAllSystems devShell;
      apps = nixpkgs.lib.genAttrs linuxSystems mkLinuxApps // nixpkgs.lib.genAttrs darwinSystems mkDarwinApps;

      # Standalone Home Manager targets for Ubuntu and other non-NixOS Linux
      # distributions. NixOS continues to use the integrated module below.
      homeConfigurations = nixpkgs.lib.genAttrs linuxSystems mkGenericLinuxHome;

      darwinConfigurations = nixpkgs.lib.genAttrs darwinSystems (system:
        darwin.lib.darwinSystem {
          inherit system;
          specialArgs = inputs // { inherit user; };
          modules = [
            { nixpkgs.hostPlatform = system; }
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
        }
      );

      nixosConfigurations = nixpkgs.lib.genAttrs linuxSystems (system: nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = inputs;
        modules = [
          disko.nixosModules.disko
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.${user} = import ./modules/nixos/home-manager.nix;
            };
          }
          ./hosts/nixos
        ];
      });
    };
}
