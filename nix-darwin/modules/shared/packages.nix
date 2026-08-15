{ pkgs }:

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
  openssh
  sqlite
  tree-sitter
  wget
  zip

  ngrok

  # Encryption and security tools
  age
  age-plugin-yubikey
  gnupg
  libfido2
  openssl

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

  # Node.js development tools
  bash-language-server
  prettier
  typescript-language-server
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
  zulu

  # Python packages
  python3
  python3Packages.virtualenv
]) ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isDarwin [ pkgs.mas ]
