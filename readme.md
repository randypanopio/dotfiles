# dotfiles

This repo contains the configuration to setup my machines. This is using [Chezmoi](https://chezmoi.io), the dotfile manager to setup the install.

The only requirement is that chezmoi is installed in the system.

## Setup Command - Unix

```shell
export GITHUB_USERNAME=randypanopio
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply $GITHUB_USERNAME
```



