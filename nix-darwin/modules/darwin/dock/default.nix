{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.local.dock;
  inherit (pkgs) stdenv dockutil;
  primaryUser = lib.escapeShellArg config.system.primaryUser;
in
{
  options = {
    local.dock.enable = mkOption {
      description = "Enable dock";
      default = stdenv.isDarwin;
      example = false;
    };

    local.dock.entries = mkOption
      {
        description = "Entries on the Dock";
        type = with types; listOf (submodule {
          options = {
            path = lib.mkOption { type = str; };
            section = lib.mkOption {
              type = str;
              default = "apps";
            };
            options = lib.mkOption {
              type = str;
              default = "";
            };
          };
        });
        readOnly = true;
      };
  };

  config =
    mkIf cfg.enable
      (
        let
          normalize = path: if hasSuffix ".app" path then path + "/" else path;
          entryURI = path: "file://" + (builtins.replaceStrings
            [" "   "!"   "\""  "#"   "$"   "%"   "&"   "'"   "("   ")"]
            ["%20" "%21" "%22" "%23" "%24" "%25" "%26" "%27" "%28" "%29"]
            (normalize path)
          );
          wantURIs = concatMapStrings
            (entry: "${entryURI entry.path}\n")
            cfg.entries;
          createEntries = concatMapStrings
            (entry: "${dockutil}/bin/dockutil --no-restart --add '${entry.path}' --section ${entry.section} ${entry.options}\n")
            cfg.entries;
        in
        {
          system.activationScripts.postActivation.text = ''
            echo >&2 "Setting up the Dock..."
            haveURIs="$(sudo -H -u ${primaryUser} -- ${dockutil}/bin/dockutil --list | ${pkgs.coreutils}/bin/cut -f2)"
            if ! diff -wu <(echo -n "$haveURIs") <(echo -n '${wantURIs}') >&2 ; then
              echo >&2 "Resetting Dock."
              sudo -H -u ${primaryUser} -- ${dockutil}/bin/dockutil --no-restart --remove all
              ${builtins.replaceStrings [ "${dockutil}/bin/dockutil" ] [ "sudo -H -u ${primaryUser} -- ${dockutil}/bin/dockutil" ] createEntries}
              sudo -H -u ${primaryUser} -- killall Dock
            else
              echo >&2 "Dock setup complete."
            fi
          '';
        }
      );
}
