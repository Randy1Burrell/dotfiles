{ config, pkgs, agenix, secrets, ... }:

let user = "randyburrell"; in
{
  age.identityPaths = [
    "/Users/${user}/.ssh/id_ed25519_agenix"
    "/Users/${user}/.ssh/id_ed25519"
  ];

  # age.secrets."github-signing-key" = {
  #   symlink = false;
  #   path = "/Users/${user}/.ssh/pgp_github.key";
  #   file =  "${secrets}/github-signing-key.age";
  #   mode = "600";
  #   owner = "${user}";
  # };

  age.secrets."id_rsa" = {
    symlink = false;
    path = "/Users/${user}/.ssh/id_rsa";
    file = "${secrets}/id_rsa.age";
    mode = "600";
    owner = "${user}";
  };

  age.secrets."authorized_keys" = {
    symlink = false;
    path = "/Users/${user}/.ssh/authorized_keys";
    file = "${secrets}/authorized_keys.age";
    mode = "600";
    owner = "${user}";
  };

  age.secrets."config_external" = {
    symlink = false;
    path = "/Users/${user}/.ssh/config_external";
    file = "${secrets}/config_external.age";
    mode = "600";
    owner = "${user}";
  };
}
