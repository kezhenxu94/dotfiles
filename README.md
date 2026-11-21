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

Keep the checkout in `/opt/staff/dotfiles`. As an admin, give each user zsh, a primary group of its own and the `staff` and `work` groups (add the owner to `work` too), and share Claude Code through `/opt/claude`:

```shell
# Linux
sudo groupadd work
sudo useradd -m -U -s /usr/bin/zsh -G staff,work <user>
sudo usermod -aG work "$USER"

# macOS (pick free GIDs); Remote Login may be limited to com.apple.access_ssh
sudo dseditgroup -o create -i <gid> work
sudo dseditgroup -o create -i <gid> <user>
sudo sysadminctl -addUser <user> -shell /bin/zsh -password -
sudo dscl . -create /Users/<user> PrimaryGroupID <gid>
for g in staff work com.apple.access_ssh; do sudo dseditgroup -o edit -a <user> -t user $g; done
sudo dseditgroup -o edit -a "$USER" -t user work

# Both: move the owner's Claude Code versions in (macOS chown clears setgid, so chmod after it)
sudo install -d /opt/claude
sudo mv ~/.local/share/claude/* /opt/claude/
sudo chown -R root:work /opt/claude && sudo chmod -R g+w /opt/claude && sudo find /opt/claude -type d -exec chmod g+s {} +
rmdir ~/.local/share/claude
```

Then each of them, the owner included, runs:

```shell
/opt/staff/dotfiles/setup.sh
```

Only the owner pulls and bootstraps; the others get its packages, mise tools, Rust toolchains and dotfiles read-only.

## Update

```shell
git -C ~/dotfiles pull  # or /opt/staff/dotfiles
~/dotfiles/setup.sh
```
