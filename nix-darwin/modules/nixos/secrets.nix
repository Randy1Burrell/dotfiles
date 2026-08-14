{ config, pkgs, agenix, secrets, ... }:

let user = "randyburrell"; in
{
  age.identityPaths = [
    "/home/${user}/.ssh/id_ed25519_agenix"
    "/home/${user}/.ssh/id_ed25519"
  ];

  # Your secrets go here
  #
  # Note: the installWithSecrets command you ran to boostrap the machine actually copies over
  #       a Github key pair. However, if you want to store the keypair in your nix-secrets repo
  #       instead, you can reference the age files and specify the symlink path here. Then add your
  #       public key in shared/files.nix.
  #
  #       If you change the key name, you'll need to update the SSH configuration in shared/home-manager.nix
  #       so Github reads it correctly.

  #
  # age.secrets."github-ssh-key" = {
  #   symlink = false;
  #   path = "/home/${user}/.ssh/id_github";
  #   file =  "${secrets}/github-ssh-key.age";
  #   mode = "600";
  #   owner = "${user}";
  #   group = "wheel";
  # };

  age.secrets."id_rsa" = {
    symlink = false;
    path = "/home/${user}/.ssh/id_rsa";
    file = "${secrets}/id_rsa.age";
    mode = "600";
    owner = user;
    group = "users";
  };

  age.secrets."authorized_keys" = {
    symlink = false;
    path = "/home/${user}/.ssh/authorized_keys";
    file = "${secrets}/authorized_keys.age";
    mode = "600";
    owner = user;
    group = "users";
  };

  age.secrets."config_external" = {
    symlink = false;
    path = "/home/${user}/.ssh/config_external";
    file = "${secrets}/config_external.age";
    mode = "600";
    owner = user;
    group = "users";
  };

}
