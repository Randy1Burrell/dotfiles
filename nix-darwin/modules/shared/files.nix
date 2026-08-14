{ githubPublicKeySource, ... }:

{
  ".ssh/id_github.pub" = {
    source = githubPublicKeySource;
  };

  ".config/emacs/config.org" = {
    source = ./config/emacs/config.org;
  };

  ".eslintrc" = {
    source = ./config/eslintrc;
  };

  ".editorconfig" = {
    source = ./config/editorconfig;
  };

}
