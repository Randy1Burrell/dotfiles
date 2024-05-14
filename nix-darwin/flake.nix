{
  description = "Randy's system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager }:
    let
      configuration = { pkgs, ... }: {
        # List packages installed in system profile. To search by name, run:
        # $ nix-env -qaP | grep wget
        environment.systemPackages = with pkgs; [
          nixpkgs-fmt
          neofetch
          vim
          zulu
        ];

        # Place global environment variables here
        environment.variables = {
          JAVA_HOME = "${pkgs.zulu}";
        };

        users = {
          users = {
            "randyburrell" = {
              home = "/Users/randyburrell";
            };
          };
        };

        # Auto upgrade nix package and the daemon service.
        services.nix-daemon.enable = true;
        # nix.package = pkgs.nix;

        # Necessary for using flakes on this system.
        nix.settings.experimental-features = "nix-command flakes";

        # Create /etc/zshrc that loads the nix-darwin environment.
        programs.zsh.enable = true; # default shell on catalina
        # programs.fish.enable = true;

        # Set Git commit hash for darwin-version.
        system.configurationRevision = self.rev or self.dirtyRev or null;

        # Used for backwards compatibility, please read the changelog before changing.
        # $ darwin-rebuild changelog
        system.stateVersion = 4;

        # The platform the configuration will be used on.
        nixpkgs.hostPlatform = "aarch64-darwin";

        homebrew = {
          enable = true;
          taps = [ ];
          brews = [ "cowsay" ];
          casks = [ ];
        };
      };
      homeconfig = { pkgs, ... }: {
        home = {
          # This is an internal compatibility configuration for home-manager,
          # only to be changed under very careful conditions.
          stateVersion = "23.05";
          sessionVariables = {
            EDITOR = "emacs";
          };
        };

        home = {
          packages = with pkgs; [ ];
        };

        programs = {
          home-manager.enable = true;

          direnv = {
            enable = true;
            enableBashIntegration = true; # see note on other shells below
            nix-direnv.enable = true;
          };

          git = {
            enable = true;
            userName = "randb1burrell";
            userEmail = "me@randyburrell.info";
            ignores = [ ".DS_Store" "*.~*" ".env" ".dir-locals.le" ];
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
              core = {
                editor = "emacs";
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
              switch = "darwin-rebuild switch --flake ~/Projects/Work/Randy/Personal/Repos/dotfiles/nix-darwin";
              vi = "vim";
              vim = "nvim";
              tmuxsrc = "tmux source-file ~/.tmux.conf";
              # tmux kill all sessions
              tmuxkillall = "tmux ls | cut -d : -f 1 | xargs -I {} tmux kill-session -t {}";
              ct = "ctags -R --exclude=.git --exclude=node_modules";
              dotfiles = "ls -a | grep '^\.' | grep --invert-match '\.DS_Store\|\.$'";
              python = "python3";
              # convenience es for editing configs;
              ev = "vi ~/.vimrc";
              et = "vi ~/.tmux.conf";
              ez = "vi ~/.zshrc";
              # convenient es for updating prompt;
              sz = "source ~/.zshrc";
              # Use the current version of emacsclient;
              emacsclient = "/Applications/Emacs.app/Contents/MacOS/bin/emacsclient";
              # Firiefox ;
              firefox = "open -a /Applications/Firefox.app";
              # Chrome ;
              chrome = "open - a \"Google Chrome\"";
              debug_chrome = "\"Google Chrome --remote-debugging-port=9222 https://localhost:3000\"";
              # Kubernetes;
              k = "kubectl";
            };

            oh-my-zsh = {
              enable = true;
              plugins = [ "git" "docker" "docker-compose" "sudo" "nvm" ];
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

          };
        };
      };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#Mac-Studio
      darwinConfigurations."Grundy-MacStudio" = nix-darwin.lib.darwinSystem {
        modules = [
          configuration
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.verbose = true;
            home-manager.users.randyburrell = homeconfig;
          }
        ];
      };

      # Expose the package set, including overlays, for convenience.
      darwinPackages = self.darwinConfigurations."Grundy-MacStudio".pkgs;
    };
}
