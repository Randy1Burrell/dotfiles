# Randy's Declarative Workstation

> Nix, nix-darwin, NixOS, Home Manager, and portable dotfiles

## Table of Contents

- [Overview](#overview)
- [Supported systems](#supported-systems)
- [Quick start](#quick-start)
  - [Existing machine](#existing-machine)
  - [New machine](#new-machine)
  - [Bootstrap Git with a YubiKey](#bootstrap-git-with-a-yubikey)
  - [Private inputs](#private-inputs)
- [Setup command](#setup-command)
  - [Interactive mode](#interactive-mode)
  - [Command reference](#command-reference)
  - [Provision a complete YubiKey](#provision-a-complete-yubikey)
  - [Local login with a YubiKey PIN](#local-login-with-a-yubikey-pin)
  - [Environment overrides](#environment-overrides)
- [Repository layout](#repository-layout)
- [Platform behavior](#platform-behavior)
  - [macOS](#macos)
  - [NixOS](#nixos)
  - [Ubuntu and other Linux distributions](#ubuntu-and-other-linux-distributions)
- [SSH, GPG, and keys](#ssh-gpg-and-keys)
  - [Git over SSH](#git-over-ssh)
  - [Multiple YubiKeys for SSH](#multiple-yubikeys-for-ssh)
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

This repository is personalized for a private secrets repository and retains
`randyburrell` as the pure-evaluation fallback. When run normally, `setup`
detects the active macOS, NixOS, or Ubuntu account, so its username may differ.
Other personalized values still need review before using this as a generic
installer.

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

Change `DOTFILES_DIR` to any destination.  The script finds `nix/flake.nix`
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

### Bootstrap Git with a YubiKey

On a machine that cannot clone the repository yet, download the standalone
bootstrap script over HTTPS. Review it before running it rather than piping a
network response directly into a shell:

```bash
BOOTSTRAP_URL="https://raw.githubusercontent.com/randy1burrell/dotfiles/main/bootstrap-gpg-ssh"
curl -fsSLo /tmp/bootstrap-gpg-ssh "$BOOTSTRAP_URL"
less /tmp/bootstrap-gpg-ssh
chmod 700 /tmp/bootstrap-gpg-ssh
/tmp/bootstrap-gpg-ssh
```

The script supports macOS, Linux, and Windows through WSL. Bash, Git, GnuPG,
and OpenSSH must already be installed; the script deliberately does not invoke
an operating-system package manager. It enables the GnuPG SSH agent, creates a
small OpenSSH include, preserves ordinary existing configuration with
timestamped backups, and waits for a YubiKey so it can show the available SSH
public key. Conventional `~/.ssh/id_ed25519` and `~/.ssh/id_rsa` identities
remain automatic fallbacks during the migration.

Once the displayed public key is registered with GitHub, clone and activate
the configuration:

```bash
DOTFILES_DIR="$HOME/dotfiles"
ssh -T git@github.com
git clone git@github.com:randy1burrell/dotfiles.git "$DOTFILES_DIR"
"$DOTFILES_DIR/setup" switch
```

Use `/tmp/bootstrap-gpg-ssh --no-wait` to install the configuration when no
YubiKey is present. Native Windows is not supported because this setup relies
on a Unix-domain agent socket; run it and Git inside WSL instead. The YubiKey
must already be attached to that WSL distribution through USB pass-through.

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

The first setup run asks for the GitHub username and saves it privately in
`~/.config/dotfiles/github-user`. Later runs reuse it without prompting. Use
the `github-user` menu item or the direct command below whenever it changes.

Every menu action is also available directly, which is preferable in scripts
and when copying diagnostic output.

### Command reference

| Command | Behavior |
|---|---|
| `./setup check` | Evaluates the selected configuration without building it. |
| `./setup build` | Builds the configuration without activating it. |
| `./setup switch` | Builds and activates the selected configuration. |
| `./setup apply` | Personalizes template values on macOS/NixOS; on generic Linux it is equivalent to `switch`. |
| `./setup apt` | On Ubuntu, installs or upgrades the APT packages declared by Nix without removing other packages. |
| `./setup snaps` | On Ubuntu, ensures `snapd` is installed and installs or refreshes the Snaps declared by Nix. |
| `./setup github-user [USERNAME]` | Shows the current username in an interactive prompt or saves a replacement. |
| `./setup clean` | Deletes generations older than seven days and optimizes the applicable Nix store/profile. |
| `./setup install-nix` | Installs upstream Nix or offers a guarded replacement that leaves nix-darwin uninstalled. |
| `./setup update-secrets` | Encrypts and pushes local secrets, then refreshes their lock entry. |
| `./setup pull-secrets` | Downloads and decrypts secrets into `~/.ssh`, backing up replaced files. |
| `./setup refresh-secrets-lock` | Refreshes only the private `secrets` entry in `flake.lock`. |
| `./setup gpg` | Starts and verifies the GPG-backed SSH agent. |
| `./setup check-keys` | Checks the expected SSH and Agenix key files and the agent socket. |
| `./setup copy-keys` | Copies a complete key set from a mounted drive. |
| `./setup create-keys` | Interactively creates the GitHub and Agenix ED25519 key pairs. |
| `./setup yubikey-login` | Adds the connected YubiKey as a local computer-login method while preserving password recovery. |
| `./setup yubikey-agenix` | Provisions or imports a hardware-backed Age identity and adds it to the Agenix recipients. |
| `./setup yubikey-setup` | Guides one connected card through PIN setup, distinct on-card OpenPGP keys, local login, and hardware-backed Agenix enrollment. |
| `./yubikey-reset [serial]` | Irreversibly clears every resettable application on exactly one connected YubiKey without confirmation prompts. |

The command-line parser passes action-specific flags to the selected helper;
for example, `./setup yubikey-setup --status`. Key commands also use the
documented environment variables and protected interactive prompts.

### Provision a complete YubiKey

Connect exactly one card, then run:

```bash
./setup yubikey-setup
```

Run the workflow separately for each YubiKey. It detects the serial number,
refuses to continue when another card could be selected accidentally, and
guides these independent application setups:

| YubiKey application | Configuration |
|---|---|
| OpenPGP | Changes the User and Admin PINs, configures a separate Reset Code, opens GnuPG's on-card generator for distinct signing/encryption/authentication keys, enables optional touch, exports the public OpenPGP and SSH keys, and can retain the signing PIN until card removal. |
| PIV | Changes the PIN and PUK, converts the management key to a random PIN-protected value, preserves or creates the slot 9a login certificate, and gives `age-plugin-yubikey` a retired slot for Agenix. |
| FIDO2 | Sets or changes the PIN used when Linux or a supported Windows configuration enrolls the card for local login. |

The suggested two-value plan uses an eight-digit everyday PIN for the OpenPGP
User PIN, PIV PIN, and FIDO2 PIN, and a separate admin/recovery value for the
OpenPGP Admin PIN and PIV PUK. These applications do not actually share PIN
storage: the official prompt for each application must receive the intended
value. Use a unique OpenPGP Reset Code and keep it with offline recovery
material; it can unblock the OpenPGP User PIN but cannot recover a blocked
Admin PIN. The random PIV management key is another credential stored on the
card under PIN protection. The script never reads, echoes, stores, or supplies
any PIN, PUK, or Reset Code as a command-line argument.

The default workflow is resumable and preserves populated key slots. Inspect a
card without changing it with:

```bash
./setup yubikey-setup --status
```

To irreversibly clear every resettable application without a confirmation
prompt, connect exactly one card immediately before running:

```bash
./yubikey-reset
./yubikey-reset 31379516 # optional serial check
```

The FIDO reset still requires touching the flashing card, as required by the
YubiKey itself. A regular YubiKey 5 has no universal factory-reset command, so
the helper resets FIDO, OATH, OpenPGP, PIV, YubiHSM Auth, Security Domain, and
both OTP slots separately. It cannot recreate the unique Yubico OTP credential
originally installed in slot 1 at the factory. Run `./yubikey-reset --help`
beforehand for the complete data-loss scope and optional access-code variables.

Generating a new OpenPGP identity on an already populated card requires the
explicit `--reset-openpgp` option and the typed phrase containing its serial
number. `--reset-piv` has the same guard but erases the macOS login certificate
and every PIV/Agenix private key on that card. Neither option resets FIDO2, so
existing passkeys are not erased. Public pre-reset inventories and final
public keys are stored under
`~/.local/state/dotfiles/yubikeys/<serial>/`; no private key, PIN, PUK, Reset
Code, or management key is written there.

```bash
./setup yubikey-setup --reset-openpgp
./setup yubikey-setup --reset-piv --reset-openpgp
```

The on-card OpenPGP and Agenix keys are intentionally non-exportable. Keep the
file-backed Agenix recovery identity, authorize every card's exported SSH key
on GitHub and each server, and publish/register every OpenPGP public key used
for commit signing. After all cards are enrolled, run `./setup update-secrets`
once to re-encrypt the Agenix files to all saved recipients. A lost card cannot
be cloned; provision a replacement with a new key, authorize its public
material, re-encrypt to the new recipient set, and revoke/remove the lost
card's public credentials.

The managed Git configuration does not hard-code one signing fingerprint.
During a commit it reads the signing fingerprint from the connected OpenPGP
card and substitutes it for Git's requested signer; verification and other GPG
operations pass through unchanged. This lets any separately provisioned card
sign after its public key is present in the local keyring and registered with
the relevant Git host. Keep only the card you intend to use connected when
signing.

For the highest assurance, provision on a clean offline machine after the
required tools are installed. On-card generation prevents private-key export,
but an offline environment also reduces the risk that a compromised host
changes the requested identity or key policy. A fully updated trusted everyday
computer is a reasonable operational choice when that stronger threat model is
not required.

### Local login with a YubiKey PIN

Run the login action once with each YubiKey connected. Each key is enrolled
independently, so any enrolled key can be used at the login screen:

```bash
./setup yubikey-login
./setup yubikey-login --status
./setup yubikey-login --disable
```

The action deliberately keeps the normal account password enabled as a
recovery method and refuses configurations that would require key-only login.
The PIN and registration mechanism differ by operating system:

| Platform | Login method and limitation |
|---|---|
| macOS | Verifies that the certificate in PIV authentication slot 9a matches its private key, safely repairs a mismatched self-signed certificate, and pairs it with the current account. FileVault pre-boot unlock still uses the account password. |
| Linux | Enrols the key with `pam_u2f`, requires its FIDO2 PIN, stores mappings in root-owned `/etc/u2f_mappings`, and adds the module as `sufficient` so password login remains available. NixOS applies the PAM portion declaratively during `switch`. |
| Windows | Opens Microsoft's protected security-key registration pages. Native FIDO2 PIN sign-in is available only on Microsoft Entra joined or hybrid joined computers whose administrator enables security-key sign-in; local accounts and personal Microsoft accounts are not supported. Run `yubikey-login-windows.ps1` directly from PowerShell when Bash is unavailable. |

On macOS, `OSStatus error -67808` or `EC signature verification failed, no
match` means the identity selected by macOS could not verify a signature from
the PIV slot 9a private key. The login helper attests on-card keys before
pairing, calculates macOS's SHA-1 hash of the verified raw public key, and pairs
only that exact identity. It never selects an unrelated hash merely because it
is the only one listed. If macOS is still exposing an old certificate, the
helper asks you to remove and reinsert the card and waits for CryptoTokenKit to
publish the current identity.

If the helper finds a certificate/private-key mismatch, it backs up the old
certificate, offers to replace only that certificate, and preserves the private
key. Remove and reinsert the YubiKey after repair, then run
`./setup yubikey-login` again. If slot 9a has an `always` or `cached` touch
policy, touch the key after entering the PIV PIN during pairing and login.

The OpenPGP, PIV, and FIDO2 applets have separate PINs unless you explicitly
set them to the same value. A passwordless Linux desktop login may also leave
GNOME Keyring or KDE Wallet locked until the account password is entered.

The `apply` action mutates template values in the checkout on macOS and NixOS.
Review or commit the working tree before using it.  On NixOS it asks for a
hostname, network interface, and disk name; selecting a disk only writes the
template value, but a later Disko installation can erase that disk.

The `clean` action is destructive by design.  Once old generations are garbage
collected, they can no longer be used for rollback.

### Environment overrides

| Variable | Purpose |
|---|---|
| `GITHUB_USER` | Supplies the username during an unattended first run; the saved preference takes precedence afterward. |
| `SYSTEM_CONFIG` | Overrides the architecture-derived flake configuration name. |
| `KEYS_MOUNT_PATH` | Selects the directory used by `copy-keys` instead of automatic removable-media discovery. |
| `SECRETS_SSH_IDENTITY` | Selects the SSH key used to clone and push the private secrets repository. |
| `AGENIX_IDENTITY_PATH` | Selects the private key used to decrypt secrets instead of `~/.ssh/id_ed25519_agenix`. |
| `AGE_YUBIKEY_IDENTITY_PATH` | Overrides `~/.config/age/yubikey-identities.txt`. |
| `AGE_YUBIKEY_RECIPIENTS_PATH` | Overrides `~/.config/age/yubikey-recipients.txt`. |
| `SECRETS_CONFIRM=yes` | Permits secrets push or installation without an interactive confirmation. |

Example:

```bash
KEYS_MOUNT_PATH=/Volumes/Keys ./setup copy-keys
```

## Repository layout

```text
.
├── setup                         # Cross-platform command and interactive menu
├── bootstrap-gpg-ssh             # Pre-Nix GPG/YubiKey SSH bootstrap
├── yubikey-setup                 # Guarded complete per-card provisioning
├── yubikey-reset                 # Non-interactive destructive card reset
├── yubikey-login                 # Local account login enrolment
├── yubikey-agenix                # Hardware-backed Agenix enrolment
├── README.md                     # This operator's guide
├── configs/                      # Historical/source configurations retained during migration
└── nix/
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

Each macOS switch updates and upgrades the declared Homebrew bundle and removes
unlisted Homebrew formulae and casks without prompting. Mac App Store apps are
excluded from cleanup because Homebrew cannot distinguish apps installed by the
configuration from apps installed independently through the App Store or MDM.

`switch` builds the nix-darwin system before running `darwin-rebuild` with
administrator privileges.  Homebrew failures are reported as part of the
activation output and do not disappear merely because the Nix build succeeded.
The build uses the username reported by `id -un` and the current absolute
`HOME`; run `setup` as the normal macOS user rather than with `sudo`.

### NixOS

The `nixosConfigurations` outputs manage the complete operating system and use
Disko for the declared partition layout.  A pristine checkout contains
`%HOST%`, `%INTERFACE%`, and `%DISK%` placeholders.  Personalize and review
them before attempting an installation:

```bash
./setup apply
git diff -- nix/hosts/nixos nix/modules/nixos
```

Do not run a Disko installation until the resolved device path has been checked
against `lsblk`.  Disko can repartition and erase the configured disk.

On an installed NixOS host, `./setup switch` obtains the current username from
`id -un`, uses the current absolute `HOME`, and delegates to
`nixos-rebuild switch`. It preserves that identity and `SSH_AUTH_SOCK` through
administrator elevation so root evaluates the same account and can fetch the
private flake input. Run `setup` as the normal NixOS user, never with `sudo`.

### Ubuntu and other Linux distributions

Non-NixOS Linux uses `homeConfigurations.<system>.activationPackage`.  It
manages the user profile and does not replace Ubuntu, repartition disks, or
enable distribution-level services.

`setup` obtains the standalone Home Manager username from `id -un` and uses the
current absolute `HOME`; run it as the normal desktop user, never with `sudo`.
This permits the same checkout to activate accounts such as `grundy-ubuntu`
without editing the repository.

The profile includes the shared packages, shell configuration, Git, SSH/GPG,
Emacs, Vim/Neovim, tmux, fonts, and selected user services. On an Ubuntu GNOME
desktop it also applies a macOS-inspired WhiteSur dark theme and cursor, a
compact always-visible bottom dock, left-side window controls, natural
scrolling, and Command-like Super-key window shortcuts. Press Super by itself
for GNOME's overview search, Super+Return for Alacritty, Super+W to close a
window, Super+M to minimize, and Super+Tab to switch applications. Log out and
back in after the first activation so the complete desktop theme and cursor are
reloaded.

The Ubuntu profile installs an Emacs desktop entry directly in
`~/.local/share/applications`, so searching for **Emacs** in GNOME opens an
`emacsclient` frame. The managed daemon starts with the user session so the
first frame does not wait for the complete configuration.

Ubuntu host packages are declared separately from the Home Manager profile.
Edit `nix/modules/linux/apt-packages.nix` for distribution-owned APT
packages and `nix/modules/linux/snaps.nix` for Snap applications. The
APT list intentionally contains only host integration needed by this setup:
Linuxbrew prerequisites, smart-card/YubiKey support, and `snapd`. Ordinary
command-line and development tools should remain in the shared Nix package
list whenever possible.

After Home Manager activates, every Ubuntu `./setup switch` updates APT
metadata, installs or upgrades the declared APT packages, installs or refreshes
the declared Snap applications on their selected channels, and then reconciles
Linuxbrew. These system operations request `sudo`; run `setup` as the normal
desktop user rather than as root. Use `./setup apt` or `./setup snaps` to run
the respective reconciliation independently. The `snaps` action also runs the
APT reconciliation first so a new machine receives `snapd` before Snap is
used. `/snap/bin` is added to the managed login path.

APT and Snap remain Ubuntu-owned mutable package systems. Nix generates their
desired manifests, but their files are not part of a Nix generation and cannot
be rolled back with Home Manager. Reconciliation never removes undeclared APT
packages or Snaps, so software installed manually by the user remains intact.
`./setup clean` clears the downloaded APT package cache but deliberately avoids
`apt autoremove` and does not delete Snap revisions.

The committed Snap list uses upstream or verified publishers. Community and
unofficial repacks are not installed unattended; add one explicitly only after
reviewing its current Snap Store publisher and confinement.

Ubuntu also uses Homebrew on Linux for the portable formulae in the macOS
Homebrew list. The first `./setup switch` installs the supported Linuxbrew
prefix and its Ubuntu build prerequisites when needed. Every switch then runs
Homebrew update, installs and upgrades the shared formulae, removes unmanaged
formulae to match the declared bundle, and cleans old versions. It also checks
the macOS cask list and includes any cask that Homebrew reports as supporting
the current Linux architecture. Casks mapped to the declared Ubuntu Snaps are
excluded to prevent duplicate applications. The macOS-only `mas` formula,
incompatible and unmapped casks, and Mac App Store applications remain
macOS-only. GnuPG, GPGME, and Pinentry are excluded from Homebrew on every
platform because Home Manager owns that complete security-sensitive toolchain
and its agents. Both Bash and Zsh load Linuxbrew's shell environment and
completions, and `./setup clean` prunes old Linuxbrew files alongside Nix
generations. Homebrew's own public GitHub repositories always use HTTPS during
these operations, independently of the personal Git URL rewrites and
GPG-backed SSH agent configuration.

Home Manager writes user-level GNOME settings only. Facilities such as the
Docker daemon, system firewall, display manager, GNOME installation, and kernel
configuration remain the responsibility of the host distribution. On a
non-GNOME Linux desktop, the installed GTK/Qt theme still applies but the GNOME
dock and window-manager preferences have no effect.

The shared Java module selects Zulu as its only JDK and exports the matching
`JAVA_HOME`. Do not add a second OpenJDK package to `home.packages`; two JDKs
both expose `lib/src.zip`, which makes Home Manager's profile build fail.

When activation encounters an unmanaged file at a Home Manager destination,
`setup` uses the backup extension `.bk` rather than silently overwriting it.

## SSH, GPG, and keys

Home Manager starts `gpg-agent` with SSH support on every platform.  Bash and
Zsh export the agent's SSH socket, and macOS also publishes it to launchd so GUI
applications can inherit the same value.

Before YubiKey provisioning, setup selects Home Manager's complete GnuPG suite
and verifies that the process behind the agent socket is the same version. On
Ubuntu it reloads the user systemd units before replacing a stale distribution
agent, which also ensures the matching `scdaemon` is launched. This prevents a
newer Nix `gpg` client from failing card discovery against an older Ubuntu
`gpg-agent` or `scdaemon`.

The agent keeps an actively used GPG or SSH credential cached for four hours,
with an eight-hour hard limit from the initial PIN/passphrase entry. Restarting
the agent, logging out, or rebooting clears the agent cache. GnuPG resets the
four-hour idle timer whenever the cached credential is used, but the hard limit
still applies.

An OpenPGP YubiKey has a separate signature policy. Its factory-style
`forced` policy requests the PIN for every commit signature and is not governed
by the agent's time limits. To let a card retain its signature PIN, connect one
YubiKey at a time and run:

```bash
./setup cache-gpg-pin
```

Confirm the persistent card change and enter the Admin PIN if Pinentry asks.
Repeat for all three YubiKeys. OpenPGP cards do not provide an hour-based
signature-PIN timer: after this change, the PIN remains valid on the card until
it is unplugged, powered down, reset, or switched away from the OpenPGP applet.
Unplug the key whenever you want to lock it immediately. Any configured
physical-touch requirement still applies to every operation.

The expected key files are:

| File | Purpose |
|---|---|
| `~/.ssh/id_ed25519` | Transitional SSH fallback and Agenix compatibility identity. |
| `~/.ssh/id_ed25519.pub` | Public half of the transitional identity. |
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
to SSH. Every host can use authentication identities exposed through
`gpg-agent`. During the YubiKey migration, OpenSSH also retains its conventional
default identity files, including `~/.ssh/id_ed25519` and `~/.ssh/id_rsa`, as
automatic fallbacks. `./setup gpg` refreshes connected readers before
displaying the agent identities.

The private `secrets` flake input and the managed Purcell Emacs checkout also
use Git over SSH.

### Multiple YubiKeys for SSH

Give each YubiKey its own OpenPGP authentication subkey and authorize all of
their SSH public keys on GitHub and every server. This gives all three tokens
the same access without sharing private key material, and a lost token can be
removed without rotating the other two.

Connect one YubiKey at a time and run:

```bash
./setup gpg
ssh-add -L
```

Record the reported public key with the token's label or serial number, then
add that public key to each destination. Repeat for all three YubiKeys. GnuPG
prioritizes authentication keys from connected cards, so an authorized active
card is selected before any other agent key. If a destination has only an old
card's public key, it cannot accept a replacement card; authorize the new
public key before removing the old one. The file-backed SSH identities remain
available until this registration work is complete.

This section applies to SSH authentication. OpenPGP signing keys and Agenix
recipients have their own selection rules and are migrated separately.

### Multiple YubiKeys for Agenix

Connect one YubiKey at a time and run the following command once for each of
the three cards:

```bash
./setup yubikey-agenix
```

If the card already contains an identity created by `age-plugin-yubikey`, the
script imports its public locator. Otherwise it generates a non-exportable
P-256 private key in the first empty retired PIV slot. It never passes
`--force`, so an occupied slot is not overwritten. The default policy requests
the PIV PIN once per card session and requires physical touch for every
decryption. The script then performs an encryption/decryption test and offers
to re-encrypt and push the private secrets repository. This requires a
PIV-capable YubiKey 4 or 5; the blue Security Key series has no PIV applet and
cannot store this identity.

Every enrolled card has a different private key. `update-secrets` encrypts each
secret to all enrolled public recipients, so any one of the three cards can
decrypt it. The private keys cannot be copied from one card to another. To
replace a lost card, provision the replacement and re-encrypt the secrets for
the remaining and replacement recipients.

The script writes only public material to:

| File | Purpose |
|---|---|
| `~/.config/age/yubikey-identities.txt` | Public locators that tell Age which card and retired slot contain each non-exportable private key. |
| `~/.config/age/yubikey-recipients.txt` | Public recipients added to every encrypted secret. |

The dedicated `~/.ssh/id_ed25519_agenix` recipient remains enabled as a
file-backed recovery path. Keep an additional protected copy somewhere separate
from the computers and YubiKeys. Removing that recovery recipient would make
the cards the only means of decrypting the data and is intentionally not
automated.

The Age identity uses the YubiKey PIV applet and therefore its PIV PIN. It is
separate from the OpenPGP PIN used for Git/SSH and the FIDO2 PIN used for Linux
or Windows login. The retired Age slot does not replace the macOS authentication
certificate in PIV slot 9a.

Do not guess the PIV PIN: a wrong value consumes one of its limited retry
attempts. If provisioning reports `Custom unprotected non-TDES management keys
are not supported`, inspect and repair only the management key with:

```bash
./setup yubikey-agenix --repair-management-key
./setup yubikey-agenix
```

The repair first displays the card's read-only PIV status, including its
remaining PIN attempts, and asks for confirmation. If the output has neither a
`Using default Management key` warning nor a `protected by PIN` message, the
card has a custom unprotected management key. Locate the saved current key
before continuing; for TDES it is 48 hexadecimal characters, is separate from
every PIN and PUK, and leaving the prompt blank will fail. The management key
cannot be recovered from the card.

The repair converts that key to a random PIN-protected TDES key but does not
change the PIV PIN, reset the PIV applet, or erase certificates and private keys
such as the macOS login credential in slot 9a. Cancel if the current management
key is unknown. Never use `ykman piv reset` as a workaround because that erases
every PIV slot.

Useful checks are:

```bash
./setup yubikey-agenix --status
./setup yubikey-agenix --test
./setup yubikey-agenix --enroll-only
```

On Ubuntu, the setup wrapper selects the managed GnuPG suite and releases
`scdaemon` before each `age-plugin-yubikey` operation. This is also done after
the private repository has been cloned through GPG-backed SSH, because that
authentication can otherwise leave the smart-card reader exclusively owned by
GnuPG and make Age incorrectly ask for an already-connected YubiKey.

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
never added to Git. Every push synchronizes `secrets.nix` recipient rules for
the dedicated recovery identity, default ED25519 identity, and all enrolled
YubiKeys. The action shows the pending Git files and requires confirmation
before committing and pushing. If live `~/.ssh/config_external` is absent, the
retained repository source is used only as bootstrap input to encryption.

`./setup pull-secrets` clones the private repository, decrypts all three files
in a temporary directory, validates them, and asks before installing them into
`~/.ssh`. Existing files receive timestamped `.bk` copies. Decryption can use
the dedicated `~/.ssh/id_ed25519_agenix` key, the transitional default SSH key,
or an enrolled YubiKey. The file-backed recovery key is deliberately not stored
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
`nix/modules/shared/config/emacs/config.org`.  Home Manager exposes it as
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

The macOS, Ubuntu, and NixOS launchers use a login daemon. While that daemon is
idle it preloads common project, version-control, programming, Markdown, and Org
libraries. Heavy optional integrations remain deferred until their command or
file type is used, and language-server startup never blocks file display.

The dashboard's project entries create or select a Perspective named for that
project before invoking Projectile. Recent-file entries detect the file's
project root, select the same project-specific Perspective, and add the opened
buffer to it. A recent file outside a recognized project stays in the current
Perspective.

### Vim and Neovim

`nix/modules/shared/config/vim/shared.vim` is loaded by both Vim and
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
`nix/modules/shared/home-manager.nix` only after choosing a replacement
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
nix flake update --flake nix
./setup check
./setup build
```

Review `nix/flake.lock` before activating an input update.

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

On Ubuntu, `agent refused operation` immediately after SSH offers a `cardno:`
identity usually means Pinentry is attached to an old terminal. The managed
Bash and Zsh startup files set `GPG_TTY` and update gpg-agent's startup terminal
whenever a new interactive shell opens. For immediate recovery in an existing
shell, run:

```bash
export GPG_TTY="$(tty)"
gpg-connect-agent updatestartuptty /bye
ssh -T git@github.com
```

Enter the YubiKey PIN when Pinentry appears and touch the key if it flashes.
If GnuPG instead reports `No pinentry`, `setup` installs a temporary
`/usr/bin/pinentry-curses` setting before evaluation, backing up an older
Home Manager link. The activated profile then replaces it with the permanent
Nix-managed Pinentry path.

Graphical Emacs uses a GTK Pinentry on Linux, with curses and TTY fallbacks for
virtual consoles and headless sessions. If EasyPG reports `Inappropriate ioctl
for device`, run `./setup switch`, restart Emacs, and retry; the PIN request
should appear as a desktop dialog instead of trying to open a nonexistent Emacs
daemon TTY.

`setup` also imports the public OpenPGP certificates published for the saved
GitHub username before asking GnuPG to inspect a connected card. This is
required on a new computer: the YubiKey holds the private ECDH operation, but
GnuPG still needs the matching public certificate in the local keyring. If a
certificate is not published on GitHub, add it to the GitHub account or import
an exported public certificate manually, then run `./setup gpg` with the card
connected. `No secret key` after that normally means the encrypted file targets
a different YubiKey key.

Home Manager is the only GnuPG provider in the managed macOS and Linux
profiles. `setup` deliberately selects `/run/current-system/sw/bin/gpgconf` on
macOS/NixOS or `~/.nix-profile/bin/gpgconf` on standalone Linux, together with
the matching client and agent programs. Activation stops a stale `dirmngr`;
Homebrew reconciliation removes undeclared GnuPG/GPGME/Pinentry formulae.

Ubuntu's `/etc/ssh/ssh_config` enables GSSAPI, so the Linux profile uses the
GSSAPI-enabled Nixpkgs OpenSSH build. Conventional `id_ed25519` and `id_rsa`
files remain automatic fallbacks when present and are not treated as errors
when absent.

ELPA vterm modules are built with vterm's vendored static libvterm rather than
linking to a Homebrew shared library. During activation, a Linux module that
specifically reports a missing `libvterm.so.0` is moved aside with its build
directory. The next `M-x vterm` rebuilds it automatically; the preserved files
remain beside the package with a `broken-system-libvterm-*` suffix.

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

The secrets workflow tries `gpg-agent` first, then automatically tries
`id_ed25519` and `id_rsa` during the migration. A one-time identity can also be
selected explicitly:

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

Standalone Home Manager still manages only the user environment. The `setup`
wrapper can install the explicitly declared APT packages and Snaps through
Ubuntu, and it enables `snapd.socket` when available, but it does not turn
arbitrary Home Manager services into Ubuntu system services. Add required host
packages to `nix/modules/linux/apt-packages.nix`, configure other daemons
through Ubuntu, or promote that machine to the NixOS configuration when
complete system management is desired.
