{ config, pkgs, agenix, homeDirectory, secrets, user, ... }:

{
  age.identityPaths = [
    "${homeDirectory}/.ssh/id_ed25519_agenix"
    "${homeDirectory}/.ssh/id_ed25519"
    "${homeDirectory}/.config/age/yubikey-identities.txt"
  ];

  # age.secrets."github-signing-key" = {
  #   symlink = false;
  #   path = "${homeDirectory}/.ssh/pgp_github.key";
  #   file =  "${secrets}/github-signing-key.age";
  #   mode = "600";
  #   owner = "${user}";
  # };

  age.secrets."id_rsa" = {
    symlink = false;
    path = "${homeDirectory}/.ssh/id_rsa";
    file = "${secrets}/id_rsa.age";
    mode = "600";
    owner = "${user}";
  };

  age.secrets."authorized_keys" = {
    symlink = false;
    path = "${homeDirectory}/.ssh/authorized_keys";
    file = "${secrets}/authorized_keys.age";
    mode = "600";
    owner = "${user}";
  };

  age.secrets."config_external" = {
    symlink = false;
    path = "${homeDirectory}/.ssh/config_external";
    file = "${secrets}/config_external.age";
    mode = "600";
    owner = "${user}";
  };
}
