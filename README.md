# MailerLite Dev Nix Configuration

This is your personal Nix configuration, initialized from the MailerLite SRE template.

## Quick Start

### Daily Usage

```bash
# Just rebuild with current config
ml-build
```

## Configuration Structure

```
~/nix-config/
├── flake.nix          # Main configuration file
├── Taskfile.yaml      # Task runner commands
```

## Dev Package Sets

As an Dev team member, you automatically get:

- **Shared packages**: Core tools (git, docker, kubectl, gh, etc.)
- **Dev packages**: Development tools (nodejs, bun, php, etc.)

## Customization

### Adding Packages

Add packages to your `flake.nix`:

```nix
# User packages
home.packages =
    mailerlite.pkgs.${system}.dev
    ++ (with pkgs; [
    # Add your own packages here
    # bob # unstable packages
    # stable.bob # stable packages
    ]);
```

### Disabling MailerLite Modules

Disable modules as needed:

```nix
mailerlite = {
  direnv.enable = false;   # Disable direnv integration
  notifier.enable = false; # Disable update notifications
  ml-build.enable = false; # Disable ml-build command
};
```

## Requirements

- **Nix**: Installed via MDM using Determinate Systems installer.

## Troubleshooting

### Shell not loading direnv

Run `direnv allow` in this directory.

## Getting Help

- Check the MailerLite Nix documentation
- Ask in the #sre-helpdesk Slack channel
- Check Bob's flake at https://github.com/robgordon89/nix-config
- Check Nikola's flake at https://github.com/nklmilojevic/nix-config
