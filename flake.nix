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
  };

  outputs = { self, nixpkgs, nixpkgs-stable, nix-darwin, home-manager, mailerlite, ... }@inputs:
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
                    # bob # unstable packages
                    # stable.bob # stable packages
                  ]);

                # Your personal home-manager configuration
                # programs.git.userEmail = "your.name@mailerlite.com";
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
