# Randy's Declarative Workstation

> Nix, nix-darwin, NixOS, Home Manager, and portable dotfiles

## Table of Contents

- [Overview](#overview)
- [Supported systems](#supported-systems)
- [Quick start](#quick-start)
  - [Existing machine](#existing-machine)
  - [New machine](#new-machine)
  - [Private inputs](#private-inputs)
- [Setup command](#setup-command)
  - [Interactive mode](#interactive-mode)
  - [Command reference](#command-reference)
  - [Environment overrides](#environment-overrides)
- [Repository layout](#repository-layout)
- [Platform behavior](#platform-behavior)
  - [macOS](#macos)
  - [NixOS](#nixos)
  - [Ubuntu and other Linux distributions](#ubuntu-and-other-linux-distributions)
- [SSH, GPG, and keys](#ssh-gpg-and-keys)
  - [Git over SSH](#git-over-ssh)
  - [Key-management commands](#key-management-commands)
- [Editor configuration](#editor-configuration)
  - [Emacs](#emacs)
  - [Vim and Neovim](#vim-and-neovim)
- [Shell, terminal, and Git](#shell-terminal-and-git)
- [Development workflow](#development-workflow)
- [Rollback and recovery](#rollback-and-recovery)
- [Troubleshooting](#troubleshooting)
  - [GitHub or private input cannot be read](#github-or-private-input-cannot-be-read)
  - [Home Manager wants to replace an existing file](#home-manager-wants-to-replace-an-existing-file)
  - [The wrong Emacs version starts on macOS](#the-wrong-emacs-version-starts-on-macos)
  - [Ubuntu does not configure an OS-level service](#ubuntu-does-not-configure-an-os-level-service)

## Overview

This is a personal, declarative workstation configuration.  Nix provides a
reproducible package set, nix-darwin manages macOS, NixOS manages complete Linux
systems, and standalone Home Manager supplies the same user environment on
Ubuntu and other non-NixOS Linux distributions.

The repository manages, among other things:

- packages and development tools;
- Git, SSH, GPG, and signed commits;
- Bash and Zsh startup files;
- Emacs, Vim, Neovim, and tmux;
- macOS defaults, applications, and the Dock;
- NixOS hardware-independent system configuration; and
- a portable Home Manager profile for generic Linux.

The main entry point is the executable `setup` script in the repository root.
It detects the operating system and CPU architecture, selects the matching
flake output, and provides the same interface on every supported platform.

This repository is personalized for the `randyburrell` account and a private
secrets repository.  It is useful as a reference for other users, but it is not
a generic installer without first changing those values.

## Supported systems

| Operating system | Architectures | Activation model | Scope |
|---|---|---|---|
| macOS            | Apple Silicon, Intel | nix-darwin + Home Manager | Complete workstation |
| NixOS            | ARM64, x86-64 | NixOS + integrated Home Manager | Complete operating system |
| Ubuntu/Linux     | ARM64, x86-64 | Standalone Home Manager | User environment only |

The corresponding Nix system names are `aarch64-darwin`,
`x86_64-darwin`, `aarch64-linux`, and `x86_64-linux`.  `setup` selects one
automatically.  Intel macOS is retained for compatibility, although Nixpkgs
26.05 is the final Nixpkgs release with upstream `x86_64-darwin` support.

## Quick start

### Existing machine

The repository can live in any directory, and `setup` can be called from any
working directory.  Point to the checkout and activate the configuration:

```bash
DOTFILES_DIR="/path/to/your/dotfiles-checkout"
"$DOTFILES_DIR/setup" switch
```

When already in the repository root, the shorter form works as usual.  Evaluate
first when testing a change:

```bash
./setup check
./setup build
./setup switch
```

### New machine

Choose any writable checkout location; no particular parent directory or
folder name is required:

```bash
DOTFILES_DIR="$HOME/dotfiles"
git clone git@github.com:randy1burrell/dotfiles.git "$DOTFILES_DIR"
"$DOTFILES_DIR/setup" switch
```

Change `DOTFILES_DIR` to any destination.  The script finds `nix-darwin/flake.nix`
relative to its own resolved location, so it does not depend on the current
working directory and can also be launched through a symlink.

On macOS and generic Linux, `switch` installs upstream Nix with the official
NixOS installer when Nix is missing.  `curl`, Git, and administrator access
must already be available.  On NixOS, Nix is part of the operating system and
`setup` will not attempt to replace it.

Before installing on macOS, `setup` repairs `/etc/synthetic.conf` to contain
one exact `nix` mount-point entry while preserving unrelated entries.  It saves
the previous file under `/var/backups`, asks macOS to create the mount point,
and retries the installer once if the installer's own cleanup removes the
entry.  This handles the common `failed to configure synthetic.conf` failure
without requiring manual file edits.

Nix installers have used both 350 and 30000 for the macOS `nixbld` group.
Before evaluating nix-darwin, `setup` reads the existing group and selects the
matching declarative Darwin configuration automatically.  Do not change the
group with macOS user-management commands.

Run `./setup install-nix` explicitly to install upstream Nix or replace an
existing receipt-managed Nix installation.  Replacement is intentionally
guarded: it requires typing `reinstall`, removes nix-darwin first, and then
removes the Nix store, installed packages, and saved system generations.  It
finishes with upstream Nix only; nix-darwin is not restored by this action.
Running `./setup switch` later will install nix-darwin again because the macOS
system configuration in this repository declares it.

If a nix-darwin uninstall was interrupted but the installer-owned Nix profile
is still usable, `install-nix` offers a non-destructive `recover` path instead.
Recovery preserves the Nix store, saves removed system artifacts under
`/var/backups`, restores the upstream daemon and shell files, and removes only
verified nix-darwin links and services.

### Private inputs

The flake has a private `secrets` input fetched from GitHub over SSH.  A new
machine must have an SSH identity with access to that repository before the
flake can evaluate.  The private key and decrypted secrets must never be
committed to this public repository.

Insert the YubiKey containing the OpenPGP authentication key, start the managed
agent, and register the public key reported by `ssh-add -L` with GitHub before
the first build:

```bash
./setup gpg
ssh-add -L
ssh -T git@github.com
```

GitHub reports that it does not provide shell access even when authentication
succeeds; that message is expected.

## Setup command

### Interactive mode

Running `./setup` without arguments opens a menu.  After an action finishes,
the menu appears again.  Select `quit` when finished.

```bash
./setup
```

Every menu action is also available directly, which is preferable in scripts
and when copying diagnostic output.

### Command reference

| Command | Behavior |
|---|---|
| `./setup check` | Evaluates the selected configuration without building it. |
| `./setup build` | Builds the configuration without activating it. |
| `./setup switch` | Builds and activates the selected configuration. |
| `./setup apply` | Personalizes template values on macOS/NixOS; on generic Linux it is equivalent to `switch`. |
| `./setup clean` | Deletes generations older than seven days and optimizes the applicable Nix store/profile. |
| `./setup install-nix` | Installs upstream Nix or offers a guarded replacement that leaves nix-darwin uninstalled. |
| `./setup update-secrets` | Encrypts and pushes local secrets, then refreshes their lock entry. |
| `./setup pull-secrets` | Downloads and decrypts secrets into `~/.ssh`, backing up replaced files. |
| `./setup refresh-secrets-lock` | Refreshes only the private `secrets` entry in `flake.lock`. |
| `./setup gpg` | Starts and verifies the GPG-backed SSH agent. |
| `./setup check-keys` | Checks the expected SSH and Agenix key files and the agent socket. |
| `./setup copy-keys` | Copies a complete key set from a mounted drive. |
| `./setup create-keys` | Interactively creates the GitHub and Agenix ED25519 key pairs. |

The command-line parser accepts arguments after `--` for flake applications
that support additional arguments.  The current key commands are configured
through environment variables and interactive prompts instead.

The `apply` action mutates template values in the checkout on macOS and NixOS.
Review or commit the working tree before using it.  On NixOS it asks for a
hostname, network interface, and disk name; selecting a disk only writes the
template value, but a later Disko installation can erase that disk.

The `clean` action is destructive by design.  Once old generations are garbage
collected, they can no longer be used for rollback.

### Environment overrides

| Variable | Purpose |
|---|---|
| `SYSTEM_CONFIG` | Overrides the architecture-derived flake configuration name. |
| `KEYS_MOUNT_PATH` | Selects the directory used by `copy-keys` instead of automatic removable-media discovery. |
| `SECRETS_SSH_IDENTITY` | Selects the SSH key used to clone and push the private secrets repository. |
| `AGENIX_IDENTITY_PATH` | Selects the private key used to decrypt secrets instead of `~/.ssh/id_ed25519_agenix`. |
| `SECRETS_CONFIRM=yes` | Permits secrets push or installation without an interactive confirmation. |

Example:

```bash
KEYS_MOUNT_PATH=/Volumes/Keys ./setup copy-keys
```

## Repository layout

```text
.
├── setup                         # Cross-platform command and interactive menu
├── README.md                    # This operator's guide
├── configs/                      # Historical/source configurations retained during migration
└── nix-darwin/
    ├── flake.nix                 # Inputs, outputs, target systems, and flake apps
    ├── flake.lock                # Reproducible dependency revisions
    ├── apps/
    │   ├── shared/               # Shared GPG and key implementations
    │   └── <system>/             # Architecture-specific app entry points
    ├── hosts/
    │   ├── darwin/               # macOS system configuration
    │   └── nixos/                # NixOS system configuration
    ├── modules/
    │   ├── darwin/               # macOS packages, Homebrew, Dock, and user setup
    │   ├── linux/                # Standalone Home Manager for generic Linux
    │   ├── nixos/                # NixOS desktop, disk, files, and services
    │   └── shared/               # Portable packages and program configuration
    └── overlays/                 # Local Nixpkgs extensions
```

Portable behavior belongs in `modules/shared`.  A platform module should only
contain behavior that cannot be expressed portably.  Generic Linux imports the
shared shell, editor, Git, SSH, GPG, package, and file configuration while
deliberately omitting NixOS-only desktop and system services.

## Platform behavior

### macOS

The `darwinConfigurations` outputs manage system packages, Home Manager,
launchd agents, macOS preferences, Homebrew formulae/casks, and applications in
`/Applications/Nix Apps`.  The Emacs daemon is started by launchd and new GUI
frames should normally be opened with:

```bash
emacsclient -c
```

`switch` builds the nix-darwin system before running `darwin-rebuild` with
administrator privileges.  Homebrew failures are reported as part of the
activation output and do not disappear merely because the Nix build succeeded.

### NixOS

The `nixosConfigurations` outputs manage the complete operating system and use
Disko for the declared partition layout.  A pristine checkout contains
`%HOST%`, `%INTERFACE%`, and `%DISK%` placeholders.  Personalize and review
them before attempting an installation:

```bash
./setup apply
git diff -- nix-darwin/hosts/nixos nix-darwin/modules/nixos
```

Do not run a Disko installation until the resolved device path has been checked
against `lsblk`.  Disko can repartition and erase the configured disk.

On an installed NixOS host, `./setup switch` delegates to `nixos-rebuild switch`
and preserves `SSH_AUTH_SOCK` so root can fetch the private flake input.

### Ubuntu and other Linux distributions

Non-NixOS Linux uses `homeConfigurations.<system>.activationPackage`.  It
manages the user profile and does not replace Ubuntu, repartition disks, or
enable distribution-level services.

The profile includes the shared packages, shell configuration, Git, SSH/GPG,
Emacs, Vim/Neovim, tmux, fonts, GTK preferences, and selected user services.
Facilities such as the Docker daemon, system firewall, display manager, and
kernel configuration remain the responsibility of the host distribution.

When activation encounters an unmanaged file at a Home Manager destination,
`setup` uses the backup extension `.bk` rather than silently overwriting it.

## SSH, GPG, and keys

Home Manager starts `gpg-agent` with SSH support on every platform.  Bash and
Zsh export the agent's SSH socket, and macOS also publishes it to launchd so GUI
applications can inherit the same value.

The expected key files are:

| File | Purpose |
|---|---|
| `~/.ssh/id_ed25519` | Legacy file-backed SSH identity and Agenix compatibility identity; GitHub does not select it by default. |
| `~/.ssh/id_ed25519.pub` | Public half of the legacy compatibility identity. |
| `~/.ssh/id_ed25519_agenix` | Agenix file-encryption identity. |
| `~/.ssh/id_ed25519_agenix.pub` | Public half of the Agenix identity. |

Private keys are mode `0600` and the SSH directory is mode `0700`.  Key scripts
must be run as the normal user, never with `sudo`.

The private `secrets` input deploys `id_rsa`, `authorized_keys`, and
`config_external` into `~/.ssh` on macOS, NixOS, and Ubuntu.  Agenix decrypts
them with `~/.ssh/id_ed25519_agenix`, with `~/.ssh/id_ed25519` retained as a
compatibility identity.  macOS and NixOS decrypt during system activation,
while Ubuntu uses the standalone Home Manager activation.

### Git over SSH

The shared Git configuration rewrites GitHub, GitLab, and Bitbucket HTTPS URLs
to SSH.  The `github.com` SSH block disables private identity files and uses
the authentication identities exposed through `gpg-agent`. The corresponding
public OpenPGP authentication key must be registered with GitHub. Non-GitHub
hosts retain the file-backed default until their YubiKey migration is complete.

The private `secrets` flake input and the managed Purcell Emacs checkout also
use Git over SSH.

### Key-management commands

`./setup gpg` creates any missing GPG configuration files, enables SSH support,
reloads the agent, publishes its socket, and reports the visible identities.

`./setup create-keys` creates unencrypted ED25519 key files after confirmation.
It never replaces an existing key without asking first.

`./setup copy-keys` searches common macOS and Linux mount locations for a
complete key set.  Use `KEYS_MOUNT_PATH` when more than one mounted source is
available or automatic discovery is inappropriate.

`./setup check-keys` verifies all four files and confirms that the GPG-agent SSH
socket is usable.

`./setup update-secrets` encrypts `id_rsa`, `authorized_keys`, and
`config_external` before placing them in the private repository.  Plaintext is
never added to Git.  The first push also creates `secrets.nix` recipient rules
for the dedicated Agenix identity and the default ED25519 identity.  The action
shows the pending Git files and requires confirmation before committing and
pushing.  If live `~/.ssh/config_external` is absent, the retained repository
source is used only as bootstrap input to encryption.

`./setup pull-secrets` clones the private repository, decrypts all three files
in a temporary directory, validates them, and asks before installing them into
`~/.ssh`.  Existing files receive timestamped `.bk` copies.  The dedicated
`~/.ssh/id_ed25519_agenix` private key must already be installed with
`copy-keys` or another secure bootstrap method; it is deliberately not stored
inside the encrypted bundle that depends on it.

Git commits are signed by default with the configured OpenPGP key.  Git LFS,
the `main` default branch, rebase-on-pull, automatic rebase stashing, and
automatic upstream creation are also declared through Home Manager.

## Editor configuration

### Emacs

Home Manager keeps `~/.emacs.d` as a Git checkout of
`git@github.com:purcell/emacs.d.git`.  A missing checkout is cloned from `main`
over SSH.  An existing checkout is handled conservatively:

- local changes are preserved and no update is attempted;
- a checkout on a branch other than `main` is preserved;
- a clean `main` branch is fast-forwarded when possible;
- an ahead or diverged `main` branch is preserved; and
- a temporary fetch failure does not invalidate an existing checkout.

The personal literate configuration is
`nix-darwin/modules/shared/config/emacs/config.org`.  Home Manager exposes it as
`~/.config/emacs/config.org` and tangles it during activation with the
Nix-managed Emacs.  Generated modules are written below `~/.emacs.d/custom` and
`~/.emacs.d/lisp`; the upstream Purcell bootstrap remains a normal Git
checkout.

Edit the Org source rather than a generated `.el` file.  Apply the result with:

```bash
./setup switch
```

The active package set uses stock Emacs from the pinned Nixpkgs release on
macOS and Linux.  On macOS, avoid an unmanaged `/Applications/Emacs.app` from an
older installation; use the launchd daemon through `emacsclient` or the managed
application under `/Applications/Nix Apps`.

### Vim and Neovim

`nix-darwin/modules/shared/config/vim/shared.vim` is loaded by both Vim and
Neovim.  Home Manager installs the compatible plugin set for each editor.
gVim, MacVim, `vi`, `view`, and `vimdiff` inherit the Vim configuration, while
flavor-specific behavior is guarded by feature checks.

Run `:VimFlavor` inside an editor to see which implementation-specific branch
was selected.  The older `vimrc` and NvChad `config.lua` remain as reference
material and are not loaded by the active configuration.

## Shell, terminal, and Git

Home Manager generates startup files for Bash and Zsh.  The shared environment
loads Nix, configures the GPG SSH socket, and installs the same command-line
tools on macOS, NixOS, and generic Linux.  Zsh completion deliberately omits
the group-writable Homebrew completion directories that would otherwise cause
`compinit` security prompts.

tmux uses the `screen-256color` terminal, mouse support, persistent sessions,
and Vim-aware pane navigation.  Its current prefix is `C-x`.  Because `C-x` is
also a fundamental Emacs prefix, change it in
`nix-darwin/modules/shared/home-manager.nix` only after choosing a replacement
that does not conflict with the desired Emacs, Vim, or shell workflow.

Git uses `vim` as its editor, signs commits with OpenPGP, pulls with rebase, and
uses a personal include for repositories below `~/Projects`.  Global ignores
cover macOS metadata, environment files, editor backups, and swap files.

## Development workflow

Use this sequence for ordinary changes:

```bash
# 1. Edit the Nix module or source configuration.

# 2. Evaluate the selected target.
./setup check

# 3. Build without changing the running system.
./setup build

# 4. Review the working tree.
git diff --check
git diff

# 5. Activate only after the previous steps pass.
./setup switch
```

The repository may contain personal, uncommitted work.  Do not discard or
rewrite unrelated changes while testing a module.  Use `SYSTEM_CONFIG` or
direct flake attribute evaluation when validating an architecture other than
the current machine.

To update pinned inputs deliberately:

```bash
nix flake update --flake nix-darwin
./setup check
./setup build
```

Review `nix-darwin/flake.lock` before activating an input update.

## Rollback and recovery

Nix keeps generations until garbage collection.  If an activation causes a
problem, do not run `./setup clean`; first use the platform's generation list
and rebuild/activation rollback facilities.

Git is the source-level rollback mechanism.  Commit stable milestones or create
a branch before broad configuration changes.  Home Manager's generic-Linux
activation backs up collisions with the `.bk` suffix.

The pre-merge Emacs repository and live files from 2026-08-12 are preserved in
the local, Git-ignored `.rollback` directory when that directory is present.
`emacs-before-merge-complete-20260812.tar.gz` contains the repository snapshot,
and `live-emacs-before-activation-20260812.tar.gz` contains the live-file
snapshot.  These archives are local recovery aids and are not expected in a
fresh clone.

## Troubleshooting

### GitHub or private input cannot be read

Check which identity SSH selects and whether GitHub accepts it:

```bash
./setup gpg
ssh-add -L
ssh -G github.com | grep -E '^(identityagent|identityfile|identitiesonly) '
ssh -T git@github.com
./setup check-keys
```

A public repository can still fail over SSH when the key is not registered with
GitHub.  The private `secrets` input additionally requires repository access.

If Nix reports that the revision locked for `secrets` no longer exists on its
`main` branch, refresh only that input and retry activation:

```bash
./setup refresh-secrets-lock
./setup switch
```

This updates the private repository revision without changing the pinned
Nixpkgs, Home Manager, nix-darwin, or other inputs.

If `update-secrets` cannot read the remote branch, make sure the GPG-backed SSH
agent exposes an identity registered with GitHub, then retry it from an
interactive terminal so any PIN or security-key prompt can be completed.

For a one-time recovery with another registered key, select it explicitly:

```bash
SECRETS_UPDATE_IDENTITY="$HOME/.ssh/id_rsa" ./setup refresh-secrets-lock
```

This override applies only to the lock refresh and does not change the default
identity declared by the SSH configuration.

If the recovery command reports that the lock is already current, the apparent
revision error was caused by SSH being unable to refresh Nix's cached checkout.
Register the authentication key reported by the GPG-backed agent with GitHub,
verify it, and then retry `switch`:

```bash
./setup gpg
ssh-add -L
ssh -T git@github.com
./setup switch
```

### Git reports that gpg-agent is older than gpg

This means another GnuPG installation, such as MacGPG/GPGTools, left an older
agent attached to the standard socket.  The setup and secrets scripts detect
this condition and restart the socket with the managed GnuPG version before a
signed commit.  Cached PINs are cleared, but keys and configuration are kept.
Run the GPG action once, then retry the secrets push:

```bash
./setup gpg
./setup update-secrets
```

The first signed commit after an agent restart can require the smart-card PIN
and a hardware touch.  Run from a normal interactive terminal and complete
both prompts.  If authorization times out, rerun `update-secrets`; plaintext
was held only in the local source files and temporary encrypted output was
discarded without pushing.

### Home Manager wants to replace an existing file

On generic Linux, activation uses the `.bk` backup extension.  If a previous
`.bk` already exists, inspect both files and move the old backup somewhere safe
before retrying.  Do not delete an existing file until its contents have been
compared with the declared replacement.

### The wrong Emacs version starts on macOS

Check both the current frame and the managed daemon:

```bash
emacs --version
emacsclient --eval emacs-version
```

If they differ, quit the unmanaged GUI application and open a frame with
`emacsclient -c`.  The managed application is placed below
`/Applications/Nix Apps`; an older `/Applications/Emacs.app` may belong to a
manual or previous installation.

### Ubuntu does not configure an OS-level service

This is expected.  Standalone Home Manager manages the user environment, not
Ubuntu's system services.  Install or enable the required daemon through Ubuntu
or promote that machine to the NixOS configuration when complete system
management is desired.
