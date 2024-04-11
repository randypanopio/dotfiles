# dotfiles

This repo contains the configuration to setup my machines. This is using [Chezmoi](https://chezmoi.io), the dotfile manager to setup the install.

The only requirement is that chezmoi is installed in the system.

## Setup Command - Unix

```shell
export GITHUB_USERNAME=randypanopio
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply $GITHUB_USERNAME
```



TODO:
// figure out auto setup of port forwarding
// setting up ssh managers
// setting up secrets, maybe
// complete language/tooling installations
// audit platform specifics