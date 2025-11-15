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
