{
  description = "MailerLite Dev Nix Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixpkgs-25.05-darwin";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # MailerLite shared configuration
    mailerlite = {
      url = "path:/Users/tmartty/.config/mailerlite/nix-config";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-stable.follows = "nixpkgs-stable";
    };

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-stable,
    nix-darwin,
    home-manager,
    mailerlite,
    nix-homebrew,
    homebrew-core,
    homebrew-cask,
    ...
  }@inputs:
    let
      system = "aarch64-darwin";
      username = "tmartty";
      hostname = "TomassMacBookPro";

      overlays = [
        (final: _prev: {
          stable = import nixpkgs-stable {
            system = final.stdenv.hostPlatform.system;
            config.allowUnfree = true;
          };
        })
      ];

      pkgs = import nixpkgs {
        inherit system overlays;
        config = {
          allowUnfree = true;
        };
      };
    in
    {
      darwinConfigurations.${hostname} = nix-darwin.lib.darwinSystem {
        inherit system;
        specialArgs = { inherit username hostname mailerlite; };
        modules = [
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              enable = true;
              user = username;
              taps = {
                "homebrew/homebrew-core" = homebrew-core;
                "homebrew/homebrew-cask" = homebrew-cask;
              };
              mutableTaps = false;
            };
          }
          # Import all MailerLite darwin modules
          mailerlite.modules.darwin.defaults
          home-manager.darwinModules.home-manager
          {
            # System configuration
            users.users.${username}.home = "/Users/${username}";
            system.primaryUser = username;

            # Used for backwards compatibility, please read the changelog before changing.
            # $ darwin-rebuild changelog
            system.stateVersion = 6;

            # Nix settings
            # Disable nix-darwin's Nix management (we use Determinate Nix)
            nix.enable = false;

            # Don't manage shell files - Determinate Nix handles /etc/zshenv
            # Users configure their own shells
            programs.zsh.enable = false;

            # Allow unfree packages
            nixpkgs.config.allowUnfree = true;
            nixpkgs.overlays = overlays;

            # Configure mailerlite darwin modules (optional)
            mailerlite = { };

            # Home Manager configuration
            home-manager = {
              useGlobalPkgs = true;
              backupFileExtension = "backup";
              users.${username} = { pkgs, ... }: {
                home.stateVersion = "25.05";
                home.enableNixpkgsReleaseCheck = false;
                # Import all MailerLite home-manager modules
                imports = [
                  mailerlite.modules.home-manager.defaults
                ];

                # Workaround: home-manager passes string instead of list to pathsToLink
                # This broke when nixpkgs started enforcing the list type strictly
                # https://github.com/nix-community/home-manager/issues/8163
                targets.darwin.linkApps.enable = false;

                # Disable the broken darwin fonts module (same pathsToLink bug)
                home.file."Library/Fonts/.home-manager-fonts-version".enable = false;

                # Configure MailerLite modules (optional)
                mailerlite = {
                  ssh = {
                    username = "tomas_martty";
                    use1PasswordAgent = true;
                    # extraConfig = ''
                    #   Host *
                    #     AddKeysToAgent yes
                    #     UseKeychain yes
                    #     IdentityFile ~/.ssh/id_rsa
                    # '';
                  };
                };

                # User packages
                home.packages =
                  mailerlite.pkgs.${system}.dev
                  ++ (with pkgs; [
                    # Add your own packages here

                    # JavaScript/TypeScript
                    nodejs_22
                    bun
                    pnpm
                    yarn

                    # PHP
                    php83
                    php83Packages.composer

                    # Python
                    python312
                    python312Packages.pip

                    # Go
                    go
                    gopls

                    # Rust
                    rustup
                  ]);

                # Your personal home-manager configuration
                programs.git.userEmail = "tomas.martty@mailerlite.com";

                programs.starship = {
                  enable = true;
                  enableZshIntegration = true;
                  settings = {
                    format = "$directory$git_branch$git_status $character";
                    add_newline = false;
                    character = {
                      success_symbol = "[➜](bold green)";
                      error_symbol = "[✗](bold red)";
                    };
                    directory = {
                      truncation_length = 3;
                      truncate_to_repo = true;
                    };
                    git_branch = {
                      symbol = " ";
                      style = "bold purple";
                    };
                    kubernetes = {
                      disabled = false;
                      symbol = "☸ ";
                    };
                    nix_shell = {
                      disabled = true;
                    };
                    gcloud = {
                      disabled = true;
                    };
                  };
                };
              };
            };
          }
        ];
      };

      # Development shell for working on this config
      devShells.${system}.default = pkgs.mkShell
        {
          buildInputs = with pkgs; [
            go-task
          ];
        };
    };
}
