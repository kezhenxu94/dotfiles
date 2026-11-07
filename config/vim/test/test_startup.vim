vim9script
# The config loads cleanly in Vim, and Neovim (which shares vimrc) is unaffected.
import './helper.vim' as h

def g:Test_PluginsLoaded()
  assert_equal(2, exists(':LspHover'), 'yegappan/lsp')
  assert_equal(2, exists(':UndotreeToggle'), 'undotree')
  assert_equal(2, exists(':Undotree'), ':Undotree alias')
  assert_true(exists('#filetypedetect') || exists('#BufRead'), 'filetype detection')
  assert_equal(1, g:java_ignore_markdown)
enddef

def g:Test_AutocompleteOption()
  assert_true(exists('+autocomplete'), 'Vim too old for the autocomplete option')
  assert_true(&autocomplete)
enddef

def g:Test_NvimStartsCleanly()
  if !executable('nvim')
    return
  endif
  var config = fnamemodify(h.root, ':h:h')
  var out = system($'env -u VIMRUNTIME -u VIM XDG_CONFIG_HOME={shellescape(config)} nvim --headless -i NONE '
    .. '+"lua io.write(vim.fn.execute([[messages]]))" +qa! 2>&1')
  assert_notmatch('\<E\d\+:\|Error', out)
  # The Vim-only plugins stay out of Neovim.
  var loaded = system($'env -u VIMRUNTIME -u VIM XDG_CONFIG_HOME={shellescape(config)} nvim --headless -i NONE '
    .. '+"lua io.write(vim.fn.exists([[:LspHover]]) .. vim.fn.exists([[:UndotreeToggle]]))" +qa! 2>&1')
  assert_equal('00', loaded->trim())
enddef
