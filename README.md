# My minimal dotfiles for both local macOS and remote Linux (including GitHub Codespaces)

| Dark | Light |
| --- | --- |
| ![Dark](https://github.com/user-attachments/assets/663538fa-b779-46a9-91f0-0514843452ce) | ![Light](https://github.com/user-attachments/assets/13a33de4-4b06-4f42-9efc-64ebe9512e83) |

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
~/dotfiles/setup.sh
```

Update the dotfiles:

```shell
git -C ~/dotfiles pull
~/dotfiles/setup.sh
```
