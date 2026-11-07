vim9script

# vim-helm (helm filetype) and undotree (nvim.undotree).
packadd vim-helm
packadd undotree

g:undotree_WindowLayout = 2
g:undotree_DiffAutoOpen = 0
g:undotree_SplitWidth = 40
g:undotree_SetFocusWhenToggle = 1
command! Undotree UndotreeToggle

g:java_ignore_markdown = 1

# Neovim defaults that change behaviour the LSP features rely on.
set nostartofline
# No "Back at original"/"match 1 of 2" noise from LSP omni completion.
set shortmess+=c

# Shell folds: functions, if/case/loops (as tree-sitter does; bashls has no
# foldingRange).
g:sh_fold_enabled = 7

# Helm templates fold like Neovim's tree-sitter (YAML structure): a line
# whose block is indented below it opens a fold that includes the line.
def HelmFold(): string
  if getline(v:lnum) =~ '^\s*$'
    return '='
  endif
  var next = nextnonblank(v:lnum + 1)
  if next > 0 && indent(next) > indent(v:lnum)
    return $'>{indent(next) / shiftwidth()}'
  endif
  return string(indent(v:lnum) / shiftwidth())
enddef

augroup kzx_vim9_filetypes
  autocmd!
  autocmd BufRead,BufNewFile *.mdx setfiletype markdown
  # gh_actions_ls only attaches to workflow files (its root_dir check in nvim).
  autocmd BufRead,BufNewFile */.{github,forgejo,gitea}/workflows/*.y{a,}ml set filetype=yaml.github-actions
  autocmd FileType sh setlocal foldmethod=syntax
  # Helm has no indent script; the global cindent/smartindent treat "key:"
  # as a C label.
  autocmd FileType helm setlocal nocindent nosmartindent foldmethod=expr foldexpr=HelmFold()
  autocmd FileType undotree setlocal nobuflisted | nnoremap <buffer> <silent> <nowait> q <Cmd>UndotreeHide<CR>
augroup END
