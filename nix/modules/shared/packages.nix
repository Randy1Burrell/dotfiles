{ pkgs }:

let
  grammarPackages = {
    bash = pkgs.tree-sitter-grammars.tree-sitter-bash;
    c = pkgs.tree-sitter-grammars.tree-sitter-c;
    cmake = pkgs.tree-sitter-grammars.tree-sitter-cmake;
    cpp = pkgs.tree-sitter-grammars.tree-sitter-cpp;
    css = pkgs.tree-sitter-grammars.tree-sitter-css;
    dart = pkgs.tree-sitter-grammars.tree-sitter-dart;
    dockerfile = pkgs.tree-sitter-grammars.tree-sitter-dockerfile;
    elisp = pkgs.tree-sitter-grammars.tree-sitter-elisp;
    go = pkgs.tree-sitter-grammars.tree-sitter-go;
    gomod = pkgs.tree-sitter-grammars.tree-sitter-gomod;
    html = pkgs.tree-sitter-grammars.tree-sitter-html;
    javascript = pkgs.tree-sitter-grammars.tree-sitter-javascript;
    json = pkgs.tree-sitter-grammars.tree-sitter-json;
    make = pkgs.tree-sitter-grammars.tree-sitter-make;
    markdown = pkgs.tree-sitter-grammars.tree-sitter-markdown;
    nix = pkgs.tree-sitter-grammars.tree-sitter-nix;
    prisma = pkgs.tree-sitter-grammars.tree-sitter-prisma;
    python = pkgs.tree-sitter-grammars.tree-sitter-python;
    rust = pkgs.tree-sitter-grammars.tree-sitter-rust;
    toml = pkgs.tree-sitter-grammars.tree-sitter-toml;
    tsx = pkgs.tree-sitter-grammars.tree-sitter-tsx;
    typescript = pkgs.tree-sitter-grammars.tree-sitter-typescript;
    yaml = pkgs.tree-sitter-grammars.tree-sitter-yaml;
  };
  sharedLibraryExtension = if pkgs.stdenv.hostPlatform.isDarwin then "dylib" else "so";
  emacsTreesitGrammars = pkgs.runCommand "emacs-treesit-grammars" { } ''
    mkdir -p "$out/lib"
    ${pkgs.lib.concatStringsSep "\n" (pkgs.lib.mapAttrsToList
      (language: grammar: ''
        ln -s ${grammar}/parser "$out/lib/libtree-sitter-${language}.${sharedLibraryExtension}"
      '')
      grammarPackages)}
  '';
in
(with pkgs; [
  # General packages for development and system management
  alacritty
  # aspell
  # aspellDicts.en
  (aspellWithDicts (dicts: [ dicts.en ]))
  bash-completion
  bat
  btop
  coreutils
  emacs
  fastfetch
  killall
  libllvm
  (if stdenv.hostPlatform.isLinux then openssh_gssapi else openssh)
  sqlite
  shellcheck
  tree-sitter
  emacsTreesitGrammars
  wget
  zip

  ngrok

  # Encryption and security tools
  age
  age-plugin-yubikey
  gnupg
  libfido2
  openssl
  yubikey-manager

  # Cloud-related tools and SDKs
  docker
  docker-compose
  terraform

  # Media-related packages
  emacs-all-the-icons-fonts
  dejavu_fonts
  ffmpeg
  fd
  font-awesome
  hack-font
  noto-fonts
  noto-fonts-color-emoji
  meslo-lgs-nf

  # Language servers and development tools
  basedpyright
  bash-language-server
  dockerfile-language-server
  gh
  gopls
  nil
  prettier
  rust-analyzer
  terraform-ls
  typescript-language-server
  vscode-langservers-extracted
  yaml-language-server
  nodejs

  # Text and terminal utilities
  htop
  hunspell
  iftop
  jetbrains-mono
  jq
  ripgrep
  tree
  tmux
  unrar
  unzip
  zsh-completions
  zsh-powerlevel10k

  nixpkgs-fmt

  # Python packages
  python3
  python3Packages.virtualenv
]) ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isDarwin [ pkgs.mas ]
