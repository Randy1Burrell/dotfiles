{ config, pkgs, agenix, homeDirectory, secrets, user, ... }:

{
  age.identityPaths = [
    "${homeDirectory}/.ssh/id_ed25519_agenix"
    "${homeDirectory}/.ssh/id_ed25519"
  ];

  age.secrets."id_rsa" = {
    symlink = false;
    path = "${homeDirectory}/.ssh/id_rsa";
    file = "${secrets}/id_rsa.age";
    mode = "600";
    owner = user;
    group = "users";
  };

  age.secrets."authorized_keys" = {
    symlink = false;
    path = "${homeDirectory}/.ssh/authorized_keys";
    file = "${secrets}/authorized_keys.age";
    mode = "600";
    owner = user;
    group = "users";
  };

  age.secrets."config_external" = {
    symlink = false;
    path = "${homeDirectory}/.ssh/config_external";
    file = "${secrets}/config_external.age";
    mode = "600";
    owner = user;
    group = "users";
  };

}
