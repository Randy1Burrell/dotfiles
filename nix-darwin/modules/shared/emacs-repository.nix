{ config, pkgs, ... }:

{
  home.activation.cloneRepo = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    emacs_dir="$HOME/.emacs.d"
    repo_url="git@github.com:purcell/emacs.d.git"

    # Use the declared default identity even on a new machine where Home
    # Manager has not linked the generated SSH config yet.
    repository_git() {
      GIT_SSH_COMMAND="${pkgs.openssh}/bin/ssh -i $HOME/.ssh/id_ed25519 -o IdentitiesOnly=yes" \
        ${pkgs.git}/bin/git "$@"
    }

    if [[ -v DRY_RUN ]]; then
      echo "Would clone or update $emacs_dir"
    elif [ ! -e "$emacs_dir" ]; then
      if ! repository_git clone --branch main "$repo_url" "$emacs_dir"; then
        echo "GitHub SSH authentication failed for $HOME/.ssh/id_ed25519." >&2
        echo "Register $HOME/.ssh/id_ed25519.pub with GitHub, then run setup switch again." >&2
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
}
