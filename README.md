# My minimal dotfiles for both local macOS and remote Linux (including GitHub Codespaces)

| Dark | Light |
| --- | --- |
| ![Dark](https://github.com/user-attachments/assets/2c7975d3-102f-4c91-92fa-da6f8bf78a35) | ![Light](https://github.com/user-attachments/assets/ec58a6b2-2c65-4cad-9772-dca0fe551c9d) |

## Requirements

* Set zsh as your login shell:

  ```shell
  chsh -s $(which zsh)
  ```

## Install

Clone onto your laptop:

```shell
git clone --recurse-submodules git@github.com:kezhenxu94/dotfiles.git ~/dotfiles
```

Install the dotfiles

```shell
~/dotfiles/install.sh
```

Update the dotfiles:

```shell
git -C ~/dotfiles pull
~/dotfiles/install.sh
```
