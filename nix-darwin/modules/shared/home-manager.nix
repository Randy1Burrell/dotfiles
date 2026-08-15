{ config, pkgs, lib, ... }:

let
  name = "randy1burrell";
  user = "randyburrell";
  email = "rb@randyburrell.info";
in
{
  home-manager = {
    enable = true;
    # path = "${config.users.users.${user}.home}/.config/home-manager";
  };

  java = {
    enable = true;
  };

  # Suggest corrections for failed commands in both interactive shells.
  pay-respects = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    options = [ "--alias" "--nocnf" ];
  };

  # Enable Bash so Home Manager's GPG agent integration is installed for
  # Bash login and interactive shells as well as Zsh.
  bash = {
    enable = true;
    # Keep the generated startup file compatible with macOS's /bin/bash 3.2
    # as well as the current Bash supplied by Nix.
    enableCompletion = false;
    shellOptions = [ "histappend" "extglob" ];
    initExtra = lib.mkMerge [
      (lib.mkBefore ''
        # Add history- and completion-based suggestions to interactive Bash.
        source ${pkgs.blesh}/share/blesh/ble.sh
      '')
      ''
        # A non-login Bash normally inherits this from its parent. Recompute it
        # when needed, while preserving an agent forwarded into a remote session.
        if [[ -z "''${SSH_AUTH_SOCK:-}" || -z "''${SSH_CONNECTION:-}" ]]; then
          unset SSH_AGENT_PID
          export SSH_AUTH_SOCK="$(${pkgs.gnupg}/bin/gpgconf --list-dirs agent-ssh-socket)"
        fi
      ''
    ];
  };

  # Shared shell configuration
  zsh = {
    enable = true; # see note on other shells below
    dotDir = config.home.homeDirectory;

    autocd = false;
    enableCompletion = true;
    completionInit = ''
      # Nix profiles and Homebrew extend fpath before completion is initialized.
      autoload -U compinit && compinit
      autoload -U bashcompinit && bashcompinit
    '';
    defaultKeymap = "emacs";

    # Extra configurations modifiable by me
    envExtra = ''
      ${builtins.readFile ./config/zsh/env}
    '';
    initContent = lib.mkMerge [
      (lib.mkBefore ''
        if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
          . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
        fi

        if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix.sh ]]; then
          . /nix/var/nix/profiles/default/etc/profile.d/nix.sh
        fi

        export PATH="$HOME/.pnpm-packages/bin:$HOME/.pnpm-packages:$PATH"
        export PATH="$HOME/.npm-packages/bin:$HOME/bin:$PATH"
        export PATH="$HOME/.local/share/bin:$PATH"

        export ALTERNATE_EDITOR="emacs"
        export EDITOR="emacsclient -t"
        export VISUAL="emacsclient -c -a emacs"

        e() {
          emacsclient -t "$@"
        }

        shell() {
          nix-shell '<nixpkgs>' -A "$1"
        }
      '')
      ''
        ${builtins.readFile ./config/zsh/interactive}

        # Load the Nix-managed theme, followed by the personal prompt config.
        source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
        ${builtins.readFile ./config/zsh/p10k.zsh}
      ''
    ];
    loginExtra = ''
      ${builtins.readFile ./config/zsh/login }
    '';
    logoutExtra = ''
      ${builtins.readFile ./config/zsh/logout }
    '';
    profileExtra = ''
      ${builtins.readFile ./config/zsh/profile}
    '';

    autosuggestion = {
      enable = true;
      strategy = [ "history" "completion" ];
    };
    syntaxHighlighting.enable = true;

    # History configuration
    history = {
      expireDuplicatesFirst = true;
      save = 60000;
      size = 70000;
      share = true;
    };

    historySubstringSearch = {
      enable = true;
      searchDownKey = "^S";
      searchUpKey = "^R";
    };

    shellAliases = {
      switch = "${config.home.homeDirectory}/Projects/Work/Randy/Personal/Repos/dotfiles/setup switch";

      vim = "nvim";

      # tmux kill all sessions
      tmuxkillall = "tmux ls | cut -d : -f 1 | xargs -I {} tmux kill-session -t {}";
      dotfiles = "ls -a | grep '^\.' | grep --invert-match '\.DS_Store\|\.$'";

      # Firiefox ;
      firefox = if pkgs.stdenv.hostPlatform.isDarwin then
        "open -a /Applications/Firefox.app"
      else
        "firefox";

      # Chrome ;
      chrome = if pkgs.stdenv.hostPlatform.isDarwin then
        "open -a \"Google Chrome\""
      else
        "google-chrome-stable";
      debug_chrome = if pkgs.stdenv.hostPlatform.isDarwin then
        "open -a \"Google Chrome\" --args --remote-debugging-port=9222 https://localhost:3000"
      else
        "google-chrome-stable --remote-debugging-port=9222 https://localhost:3000";

      # Kubernetes;
      k = "kubectl";

      # pnpm is a javascript package manager
      pn = "pnpm";
      px = "pnpx";

      # Use difftastic, syntax-aware diffing
      diff = "difft";

      # Always color ls and group directories
      ls = "ls --color=auto";

      # Ripgrep alias
      search = "rg -p --glob '!node_modules/*'  $@";
    };

    cdpath = [ "~/.local/share/src" ];
  };

  direnv = {
    enable = true;
    enableBashIntegration = true; # see note on other shells below
    nix-direnv.enable = true;
  };


  git = {
    enable = true;
    ignores = [ ".DS_Store" "*.~*" ".env" ".envrc" ".dir-locals.le" "*.swp" ];
    lfs = {
      enable = true;
    };
    includes = [{
      path = "~/.gitconfig-personal";
      condition = "gitdir:~/Projects";
    }];

    signing = {
      key = "B3F07B6956A7DD05EC6BC6174E735276489B2667";
      signByDefault = true;
      format = "openpgp";
    };

    settings = {
      user = {
        inherit email name;
      };

      init.defaultBranch = "main";
      core = {
        editor = "vim";
        autocrlf = "input";
      };
      commit.gpgSign = true;
      pull.rebase = true;
      rebase.autoStash = true;
      push.autoSetupRemote = true;
      url = {
        "ssh://git@github.com" = {
          insteadOf = "https://github.com";
        };

        "ssh://git@gitlab.com" = {
          insteadOf = "https://gitlab.com";
        };

        "ssh://git@bitbucket.org" = {
          insteadOf = "https://bitbucket.org";
        };
      };
    };
  };

  diff-so-fancy = {
    enable = true;
    enableGitIntegration = true;
    pagerOpts = [
      "--tabs=4"
      "-RFX"
    ];
    settings = {
      changeHunkIndicators = true;
      markEmptyLines = true;
      rulerWidth = 1;
      stripLeadingSymbols = true;
      useUnicodeRuler = true;
    };
  };

  neovim = {
    enable = true;
    # Preserve the behavior from Home Manager releases before 26.05.
    withPython3 = true;
    withRuby = true;
    plugins = with pkgs.vimPlugins; [
      vim-airline
      vim-airline-themes
      vim-startify
      vim-tmux-navigator
    ];
    extraConfig = ''
      ${builtins.readFile ./config/vim/shared.vim}
      ${builtins.readFile ./config/vim/BufOnly.vim}
      ${builtins.readFile ./config/vim/Scratch.vim}
    '';
    # Keep `vim` as Vim and `nvim` as Neovim so both can be tested and used.
    viAlias = false;
    vimAlias = false;
  };

  vim = {
    enable = true;
    plugins = with pkgs.vimPlugins; [
      vim-airline
      vim-airline-themes
      vim-startify
      vim-tmux-navigator
    ];
    settings = { };
    extraConfig = ''
      ${builtins.readFile ./config/vim/shared.vim}
      ${builtins.readFile ./config/vim/BufOnly.vim}
      ${builtins.readFile ./config/vim/Scratch.vim}
    '';
  };

  alacritty = {
    enable = true;
    settings = {
      cursor = {
        style = "Block";
      };

      window = {
        opacity = 0.85;
        padding = {
          x = 14;
          y = 14;
        };
      };

      font = {
        normal = {
          family = "MesloLGS NF";
          style = "Regular";
        };
        size = lib.mkMerge [
          (lib.mkIf pkgs.stdenv.hostPlatform.isLinux 10)
          (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin 14)
        ];
      };

      colors = {
        primary = {
          background = "0x1f2528";
          foreground = "0xc0c5ce";
        };

        normal = {
          black = "0x1f2528";
          red = "0xec5f67";
          green = "0x99c794";
          yellow = "0xfac863";
          blue = "0x6699cc";
          magenta = "0xc594c5";
          cyan = "0x5fb3b3";
          white = "0xc0c5ce";
        };

        bright = {
          black = "0x65737e";
          red = "0xec5f67";
          green = "0x99c794";
          yellow = "0xfac863";
          blue = "0x6699cc";
          magenta = "0xc594c5";
          cyan = "0x5fb3b3";
          white = "0xd8dee9";
        };
      };
    };
  };

  ssh = {
    enable = true;
    enableDefaultConfig = false;
    includes = [ "${config.home.homeDirectory}/.ssh/config_external" ];
    settings = {
      "*" = {
        # Keep gpg-agent available while selecting the same default ED25519
        # identity consistently in Bash, Zsh, and non-interactive Git calls.
        IdentityAgent = "SSH_AUTH_SOCK";
        IdentityFile = "~/.ssh/id_ed25519";
        IdentitiesOnly = true;
        ForwardAgent = false;
        AddKeysToAgent = "no";
        Compression = false;
        ServerAliveInterval = 0;
        ServerAliveCountMax = 3;
        HashKnownHosts = false;
        UserKnownHostsFile = "~/.ssh/known_hosts";
        ControlMaster = "no";
        ControlPath = "~/.ssh/master-%r@%n:%p";
        ControlPersist = "no";
      };

    };
  };

  tmux = {
    enable = true;
    plugins = with pkgs.tmuxPlugins; [
      vim-tmux-navigator
      sensible
      yank
      prefix-highlight
      {
        plugin = power-theme;
        extraConfig = ''
          set -g @tmux_power_theme 'gold'
        '';
      }
      {
        plugin = resurrect; # Used by tmux-continuum

        # Use XDG data directory
        # https://github.com/tmux-plugins/tmux-resurrect/issues/348
        extraConfig = ''
          set -g @resurrect-dir '~/.cache/tmux/resurrect'
          set -g @resurrect-capture-pane-contents 'on'
          set -g @resurrect-pane-contents-area 'visible'
        '';
      }
      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '5' # minutes
        '';
      }
    ];
    terminal = "screen-256color";
    prefix = "C-x";
    escapeTime = 10;
    historyLimit = 50000;
    extraConfig = ''
      # Remove Vim mode delays
      set -g focus-events on

      # Enable full mouse support
      set -g mouse on

      # -----------------------------------------------------------------------------
      # Key bindings
      # -----------------------------------------------------------------------------

      # Unbind default keys
      unbind C-b
      unbind '"'
      unbind %

      # Split panes, vertical or horizontal
      bind-key x split-window -v
      bind-key v split-window -h

      # Move around panes with vim-like bindings (h,j,k,l)
      bind-key -n M-k select-pane -U
      bind-key -n M-h select-pane -L
      bind-key -n M-j select-pane -D
      bind-key -n M-l select-pane -R

      # Smart pane switching with awareness of Vim splits.
      # This is copy paste from https://github.com/christoomey/vim-tmux-navigator
      is_vim="ps -o state= -o comm= -t '#{pane_tty}' \
        | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?)(diff)?$'"
      bind-key -n 'C-h' if-shell "$is_vim" 'send-keys C-h'  'select-pane -L'
      bind-key -n 'C-j' if-shell "$is_vim" 'send-keys C-j'  'select-pane -D'
      bind-key -n 'C-k' if-shell "$is_vim" 'send-keys C-k'  'select-pane -U'
      bind-key -n 'C-l' if-shell "$is_vim" 'send-keys C-l'  'select-pane -R'
      tmux_version='$(tmux -V | sed -En "s/^tmux ([0-9]+(.[0-9]+)?).*/\1/p")'
      if-shell -b '[ "$(echo "$tmux_version < 3.0" | bc)" = 1 ]' \
        "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\'  'select-pane -l'"
      if-shell -b '[ "$(echo "$tmux_version >= 3.0" | bc)" = 1 ]' \
        "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\\\'  'select-pane -l'"

      bind-key -T copy-mode-vi 'C-h' select-pane -L
      bind-key -T copy-mode-vi 'C-j' select-pane -D
      bind-key -T copy-mode-vi 'C-k' select-pane -U
      bind-key -T copy-mode-vi 'C-l' select-pane -R
      bind-key -T copy-mode-vi 'C-\' select-pane -l
    '';
  };
}
