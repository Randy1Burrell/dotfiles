{ config, lib, pkgs, ... }:

let
  sshPackage = if pkgs.stdenv.hostPlatform.isLinux then pkgs.openssh_gssapi else pkgs.openssh;
in

{
  home.activation.cloneRepo = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    emacs_dir="$HOME/.emacs.d"
    repo_url="git@github.com:purcell/emacs.d.git"

    # Use gpg-agent even on a new machine where Home Manager has not linked the
    # generated SSH config yet. Conventional identity files remain available
    # as migration fallbacks until every YubiKey has been authorized.
    repository_git() {
      SSH_AUTH_SOCK="$(${pkgs.gnupg}/bin/gpgconf --list-dirs agent-ssh-socket)" \
        GIT_SSH_COMMAND="${sshPackage}/bin/ssh -o IdentitiesOnly=no" \
        ${pkgs.git}/bin/git "$@"
    }

    if [[ -v DRY_RUN ]]; then
      echo "Would clone or update $emacs_dir"
    elif [ ! -e "$emacs_dir" ]; then
      if ! repository_git clone --branch main "$repo_url" "$emacs_dir"; then
        echo "GitHub SSH authentication through gpg-agent and the migration fallback keys failed." >&2
        echo "Insert an authorized YubiKey or register a fallback public key, then run setup switch again." >&2
        exit 1
      fi
    elif [ -d "$emacs_dir/.git" ]; then
      current_branch="$(repository_git -C "$emacs_dir" branch --show-current)"

      if [ -n "$(repository_git -C "$emacs_dir" status --porcelain)" ]; then
        echo "Preserving $emacs_dir: the checkout has local changes."
      elif [ "$current_branch" != main ]; then
        echo "Preserving $emacs_dir: it is on branch $current_branch, not main."
      elif ! repository_git -C "$emacs_dir" fetch --quiet --no-tags "$repo_url" main; then
        echo "Warning: could not check for Emacs repository updates; using the existing checkout." >&2
      elif repository_git -C "$emacs_dir" merge-base --is-ancestor HEAD FETCH_HEAD; then
        repository_git -C "$emacs_dir" merge --ff-only FETCH_HEAD
      elif repository_git -C "$emacs_dir" merge-base --is-ancestor FETCH_HEAD HEAD; then
        echo "Preserving $emacs_dir: the local main branch is ahead of upstream."
      else
        echo "Preserving $emacs_dir: the local main branch has diverged from upstream." >&2
      fi
    else
      echo "Cannot update $emacs_dir: it exists but is not a Git checkout." >&2
      exit 1
    fi
  '';

  home.activation.tangleEmacsConfig = config.lib.dag.entryAfter [
    "cloneRepo"
    "linkGeneration"
  ] ''
    if [[ -v DRY_RUN ]]; then
      echo "Would tangle the Emacs configuration"
    elif [ ! -d "$HOME/.emacs.d/.git" ]; then
      echo "Cannot tangle Emacs configuration: $HOME/.emacs.d is not a Git checkout." >&2
      exit 1
    else
      export HOME
      ${pkgs.emacs-nox}/bin/emacs --batch --quick \
        --eval '(require (quote org))' \
        --eval '(org-babel-tangle-file "${./config/emacs/config.org}")'
    fi
  '';

  # Older ELPA vterm modules may have linked against Linuxbrew's unversioned
  # runtime environment. Quarantine only modules whose loader explicitly says
  # libvterm.so.0 is missing; the shared Emacs configuration will rebuild them
  # with vterm's vendored static library on first use.
  home.activation.repairBrokenVtermModule = config.lib.dag.entryAfter [
    "tangleEmacsConfig"
  ] ''
    ${lib.optionalString pkgs.stdenv.hostPlatform.isLinux ''
      if [[ -v DRY_RUN ]]; then
        echo "Would inspect existing Emacs vterm modules"
      else
        for vterm_module in "$HOME"/.emacs.d/elpa-*/vterm-*/vterm-module.so; do
          [ -e "$vterm_module" ] || continue
          if ${pkgs.glibc.bin}/bin/ldd "$vterm_module" 2>&1 | \
             ${pkgs.gnugrep}/bin/grep -Fq 'libvterm.so.0 => not found'; then
            vterm_directory="$(${pkgs.coreutils}/bin/dirname -- "$vterm_module")"
            backup_suffix="broken-system-libvterm-$(${pkgs.coreutils}/bin/date +%Y%m%d%H%M%S)-$$"
            ${pkgs.coreutils}/bin/mv -- \
              "$vterm_module" "$vterm_module.$backup_suffix"
            if [ -d "$vterm_directory/build" ]; then
              ${pkgs.coreutils}/bin/mv -- \
                "$vterm_directory/build" \
                "$vterm_directory/build.$backup_suffix"
            fi
            echo "Quarantined broken vterm module $vterm_module; Emacs will rebuild it on first use."
          fi
        done
      fi
    ''}
  '';
}
