# dotfiles

Minimal dotfiles for macOS and Linux (including GitHub Codespaces).

## Install

```shell
git clone git@github.com:kezhenxu94/dotfiles.git ~/dotfiles
~/dotfiles/bootstrap.sh
```

`bootstrap.sh` installs packages (and sets zsh as the login shell), then runs `setup.sh` to symlink the dotfiles into `$HOME`. Run `setup.sh` alone to only link the dotfiles.

With passwordless sudo, packages and mise tools (`mise install --system`) go to `/opt/staff`, owned by the installing user and read-only for the `staff` group; otherwise to `~/usr/local`.

## Share with other users

Keep the checkout in `/opt/staff/dotfiles` and add the users to `staff`; each of them runs:

```shell
/opt/staff/dotfiles/setup.sh
```

Only the owner pulls and bootstraps; the others get its packages, mise tools and dotfiles read-only.

## Update

```shell
git -C ~/dotfiles pull  # or /opt/staff/dotfiles
~/dotfiles/setup.sh
```
