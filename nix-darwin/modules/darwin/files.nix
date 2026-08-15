{ user, config, pkgs, ... }:

let
  xdg_configHome = "${config.users.users.${user}.home}/.config";
  xdg_dataHome   = "${config.users.users.${user}.home}/.local/share";
  xdg_stateHome  = "${config.users.users.${user}.home}/.local/state"; in
{

  # Raycast script so that "Run Emacs" is available and uses Emacs daemon
  "${xdg_dataHome}/bin/emacsclient" = {
    executable = true;
    text = ''
      #!/bin/zsh
      #
      # Required parameters:
      # @raycast.schemaVersion 1
      # @raycast.title Run Emacs
      # @raycast.mode silent
      #
      # Optional parameters:
      # @raycast.packageName Emacs
      # @raycast.icon ${xdg_dataHome}/img/icons/Emacs.icns
      # @raycast.iconDark ${xdg_dataHome}/img/icons/Emacs.icns

      if (( $# == 0 )); then
        # Raycast launches this script without arguments. Open a new GUI frame
        # without blocking Raycast while that frame remains open.
        exec ${pkgs.emacs}/bin/emacsclient -c -n
      else
        # Preserve every option supplied by callers such as Magit's
        # with-editor integration. In particular, do not force -c or -n:
        # Git must wait until the commit-message buffer is finished.
        exec ${pkgs.emacs}/bin/emacsclient "$@"
      fi
    '';
  };
}
