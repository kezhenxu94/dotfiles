# dotfiles

Minimal dotfiles for macOS and Linux (including GitHub Codespaces).

## Install

```shell
git clone git@github.com:kezhenxu94/dotfiles.git ~/dotfiles
~/dotfiles/bootstrap.sh
```

`bootstrap.sh` installs packages (and sets zsh as the login shell), then runs `setup.sh` to symlink the dotfiles into `$HOME`. Run `setup.sh` alone to only link the dotfiles.

## Update

```shell
git -C ~/dotfiles pull
~/dotfiles/setup.sh
```
