{ config, pkgs, ... }:

let
  emacsOverlaySha256 = "sha256:0n9h20j3dv4rn2rlhqhvp1ig7lc6ln2iyivz3wf6wd14imasphbk";
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
