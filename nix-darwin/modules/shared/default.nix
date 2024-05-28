{ config, pkgs, ... }:

let
  emacsOverlaySha256 = "sha256:1il1vbawhhp3blgx609mcmxrm8pgzm9flkn6agzc16i52vd9abxh";
in
{

  nixpkgs = {
    config = {
      allowUnfree = true;
      allowBroken = true;
      allowInsecure = false;
      allowUnsupportedSystem = true;
    };

    overlays =
      # Apply each overlay found in the /overlays directory
      let path = ../../overlays; in with builtins;
      map (n: import (path + ("/" + n)))
        (filter
          (n: match ".*\\.nix" n != null ||
          pathExists (path + ("/" + n + "/default.nix")))
          (attrNames (readDir path)))

      ++ [
        (import (builtins.fetchTarball {
          url = "https://github.com/nix-community/emacs-overlay/archive/master.tar.gz";
          sha256 = emacsOverlaySha256;
        }))
      ];
  };
}
