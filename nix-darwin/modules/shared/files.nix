{ githubPublicKeySource, ... }:

{
  # Git reads ~/.config/git/config and then ~/.gitconfig. Manage the latter as
  # an intentionally empty compatibility file so a legacy copy cannot override
  # the declarative Home Manager configuration. Existing files are backed up by
  # the platform activation settings.
  ".gitconfig" = {
    text = ''
      # Git configuration is managed at ~/.config/git/config by Home Manager.
    '';
  };

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
