{ config, pkgs, lib, ... }:

let
  name = "randy1burrell";
  user = "randyburrell";
  email = "rb@randyburrell.info";
in
{
  # Shared shell configuration
  zsh = {
    enable = true; # see note on other shells below

    autocd = true;
    enableCompletion = true;
    defaultKeymap = "emacs";

    # Extra configurations modifiable by me
    envExtra = ". ~/.zsh/env";
    initExtra = ". ~/.zsh/interactive";
    loginExtra = ". ~/.zsh/login";
    logoutExtra = ". ~/.zsh/logout";
    profileExtra = ". ~/.zsh/profile";

    autosuggestion = {
      enable = true;
    };

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
      switch = "cd /Users/randyburrell/Projects/Work/Randy/Personal/Repos/dotfiles/nix-darwin && nix run .\\#build && nix run .\\#build-switch && cd -";

      # vi = "vi";
      # vim = "nvim";

      # tmux kill all sessions
      tmuxkillall = "tmux ls | cut -d : -f 1 | xargs -I {} tmux kill-session -t {}";
      dotfiles = "ls -a | grep '^\.' | grep --invert-match '\.DS_Store\|\.$'";

      # convenient es for updating prompt;
      sz = "source ~/.zshrc";

      # Firiefox ;
      firefox = "open -a /Applications/Firefox.app";

      # Chrome ;
      chrome = "open - a \"Google Chrome\"";
      debug_chrome = "\"Google Chrome --remote-debugging-port=9222 https://localhost:3000\"";

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


    # Plugin Manager
    zplug = {
      enable = true;
      plugins = [
        { name = "zsh-users/zsh-autosuggestions"; } # Simple plugin installation
        { name = "zsh-users/zsh-completions"; }
        { name = "zsh-users/zsh-syntax-highlighting"; }
        { name = "nix-community/nix-zsh-completions"; }
        { name = "romkatv/powerlevel10k"; tags = [ as:theme depth:1 ]; } # Installations with additional options. For the list of options, please refer to Zplug README.
      ];
    };


    cdpath = [ "~/.local/share/src" ];
    initExtraFirst = ''
      if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
      fi

      if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix.sh ]]; then
        . /nix/var/nix/profiles/default/etc/profile.d/nix.sh
      fi


      # Define variables for directories
      export PATH=$HOME/.pnpm-packages/bin:$HOME/.pnpm-packages:$PATH
      export PATH=$HOME/.npm-packages/bin:$HOME/bin:$PATH
      export PATH=$HOME/.local/share/bin:$PATH

      # Remove history data we don't want to see
      # export HISTIGNORE="pwd:ls:cd"


      # Emacs is my editor
      export ALTERNATE_EDITOR="emacs"
      export EDITOR="emacsclient -t"
      export VISUAL="emacsclient -c -a emacs"

      e() {
          emacsclient -t "$@"
      }

      # nix shortcuts
      shell() {
          nix-shell '<nixpkgs>' -A "$1"
      }

    '';
  };

  direnv = {
    enable = true;
    enableBashIntegration = true; # see note on other shells below
    nix-direnv.enable = true;
  };


  git = {
    enable = true;
    ignores = [ ".DS_Store" "*.~*" ".env" ".dir-locals.le" "*.swp" ];
    userName = name;
    userEmail = email;
    lfs = {
      enable = true;
    };
    extraConfig = { };
    includes = [{
      path = "~/.gitconfig-personal";
      condition = "gitdir:~/Projects";
    }];

    diff-so-fancy = {
      enable = true;
      changeHunkIndicators = true;
      markEmptyLines = true;
      rulerWidth = 1;
      stripLeadingSymbols = true;
      useUnicodeRuler = true;
      pagerOpts = [
        "--tabs=4"
        "-RFX"
      ];
    };

    # Enable GPG signing
    signing = {
      key = "306FAA9223DD193A";
      signByDefault = true;
    };

    extraConfig = {
      commit = {
        gpgsign = true;
      };
      pull.rebase = true;
      rebase.autoStash = true;
      core = {
        editor = "emacs";
        autocrlf = "input";
      };
      init = {
        defaultBranch = "main";
      };
      push = {
        autoSetupRemote = true;
      };
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

  neovim = {
    enable = true;
    extraLuaConfig = ''
      -- Write lua code here
      -- or interpolate files like this:
      ${builtins.readFile ./config/neovim/config.lua}
    '';
    viAlias = true;
    vimAlias = true;
  };

  vim = {
    enable = true;
    plugins = with pkgs.vimPlugins; [
      vim-airline
      vim-airline-themes
      vim-startify
      vim-tmux-navigator
    ];
    settings = { ignorecase = true; };
    extraConfig = ''
      ${builtins.readFile ./config/vim/vimrc}
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
    includes = [
      (lib.mkIf pkgs.stdenv.hostPlatform.isLinux
        "/home/${user}/.ssh/config_external"
      )
      (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin
        "/Users/${user}/.ssh/config_external"
      )
    ];
    matchBlocks = {
      "github.com" = {
        identitiesOnly = true;
        identityFile = [
          (lib.mkIf pkgs.stdenv.hostPlatform.isLinux
            "/home/${user}/.ssh/id_github"
          )
          (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin
            "/Users/${user}/.ssh/id_github"
          )
        ];
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
