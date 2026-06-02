# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with this user's Nix configuration.

## What this is

This is a MailerLite **dev team** personal Nix configuration at `~/nix-config`. It's a nix-darwin + home-manager flake that references a shared company flake at `~/.config/mailerlite/nix-config`.

## Key variables

At the top of `flake.nix`:
- `username` -- macOS username
- `hostname` -- machine hostname, must match `darwinConfigurations.<hostname>`

## Common tasks

### Add a package

In `flake.nix`, find `home.packages` and add to the list after `with pkgs;`:

```nix
home.packages =
  mailerlite.pkgs.${system}.dev
  ++ (with pkgs; [
    htop       # add packages here
    neovim
  ]);
```

Then run: `ml-build`

Search for package names at https://search.nixos.org/packages

Use `stable.<pkg>` for stable-channel packages (e.g. `stable.terraform`).

### Change SSH username

In `flake.nix`, find the `mailerlite.ssh` block:

```nix
mailerlite = {
  ssh = {
    username = "bob";  # change to a string if different from macOS username
  };
};
```

Then run: `ml-build`

### Enable 1Password SSH agent

In the `mailerlite.ssh` block, set:

```nix
use1PasswordAgent = true;
```

Then run: `ml-build`

### Add shell aliases

Inside `home-manager.users.${username}`:

```nix
programs.zsh.shellAliases = {
  k = "kubectl";
  ll = "eza -la";
};
```

### Add Starship prompt

Inside `home-manager.users.${username}`:

```nix
programs.starship = {
  enable = true;
  enableZshIntegration = true;
  settings = {
    character.success_symbol = "[>](bold green)";
    gcloud.disabled = true;
  };
};
```

### Add extra SSH config

```nix
mailerlite.ssh.extraConfig = ''
  Host myserver
    HostName example.com
    User deploy
'';
```

### Disable a MailerLite module

> Not recommended !

```nix
mailerlite = {
  notifier.enable = false;
  direnv.enable = false;
  ml-build.enable = false;
  zsh.enable = false;
  ssh.enable = false;
};
```

## Build commands

All from `~/nix-config`:

- `ml-build` -- update shared config and rebuild (from anywhere)
- `task build` -- same as ml-build
- `task update-build` -- update ALL flake inputs and rebuild
- `task gc` -- garbage collect old Nix packages

## File structure

- `flake.nix` -- the only file you typically edit
- `flake.lock` -- locked dependency versions (updated by `task update`)
- `Taskfile.yaml` -- task runner commands

## Important notes

- This flake uses `--impure` and `--refresh` flags during builds
- `nix.enable = false` because Determinate Nix manages itself
- `programs.zsh.enable = false` at darwin level because Determinate Nix manages `/etc/zshenv`
- The `targets.darwin.linkApps.enable = false` and fonts workaround are for a known home-manager bug (https://github.com/nix-community/home-manager/issues/8163)
- Dev template does not include language-specific packages (nodejs, php, etc.) -- users add their own
