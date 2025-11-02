if &compatible
  set nocompatible
endif

let g:has_async = v:version >= 800

set encoding=UTF-8

if filereadable(expand("~/.vimrc.bundles.local"))
  source ~/.vimrc.bundles.local
endif

if !has("nvim")
  packadd catppuccin
  let theme = trim(system("dark-notify -e || echo \"$THEME\" | grep light"))
  if theme != "dark"
    colorscheme catppuccin_latte
  else
    colorscheme catppuccin_mocha
  endif
  hi Normal guibg=NONE ctermbg=NONE
endif
