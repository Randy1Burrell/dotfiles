[
  # Ubuntu-owned host integration. Prefer nixpkgs for ordinary user tools.
  "ca-certificates"

  # Linuxbrew bootstrap requirements.
  "build-essential"
  "curl"
  "file"
  "git"
  "procps"

  # Smart-card and YubiKey login support.
  "libccid"
  "libpam-u2f"
  "pcscd"

  # Snap remains an Ubuntu system service; Nix declares what setup installs.
  "snapd"
]
