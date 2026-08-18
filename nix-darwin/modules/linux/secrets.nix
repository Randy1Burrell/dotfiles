{ config, secrets, ... }:

let
  homeDirectory = config.home.homeDirectory;
in
{
  # Standalone Home Manager cannot use the system-level Agenix module used by
  # NixOS. Decrypt the same secrets in the user's activation instead.
  age.identityPaths = [
    "${homeDirectory}/.ssh/id_ed25519_agenix"
    "${homeDirectory}/.ssh/id_ed25519"
    "${homeDirectory}/.config/age/yubikey-identities.txt"
  ];

  age.secrets."id_rsa" = {
    symlink = false;
    path = "${homeDirectory}/.ssh/id_rsa";
    file = "${secrets}/id_rsa.age";
    mode = "600";
  };

  age.secrets."authorized_keys" = {
    symlink = false;
    path = "${homeDirectory}/.ssh/authorized_keys";
    file = "${secrets}/authorized_keys.age";
    mode = "600";
  };

  age.secrets."config_external" = {
    symlink = false;
    path = "${homeDirectory}/.ssh/config_external";
    file = "${secrets}/config_external.age";
    mode = "600";
  };
}
