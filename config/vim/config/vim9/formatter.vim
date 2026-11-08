vim9script
# Port of config/nvim/lua/config/lsp/formatter.lua (conform.nvim): format on
# save with external formatters, falling back to the language server.

import autoload 'lsp/buffer.vim' as lspbuf

# $FILENAME is replaced with the buffer's file name; the buffer goes to stdin.
const formatters: dict<list<string>> = {
  stylua: ['stylua', '--search-parent-directories', '--respect-ignores', '--stdin-filepath', '$FILENAME', '-'],
  jq: ['jq', '--indent', '$SHIFTWIDTH'],
  gofmt: ['gofmt'],
  shfmt: ['shfmt', '-filename', '$FILENAME'],
  eslint_d: ['eslint_d', '--fix-to-stdout', '--stdin', '--stdin-filename', '$FILENAME'],
  prettier: ['prettier', '--stdin-filepath', '$FILENAME'],
  prettierd: ['prettierd', '$FILENAME'],
  yq: ['yq', '-P', '-'],
  black: ['black', '--stdin-filename', '$FILENAME', '--quiet', '-'],
  'google-java-format': ['google-java-format', '-'],
}

# A list runs every available formatter in turn; {first: [...]} runs only the
# first available one (stop_after_first). Projects override it per filetype in
# g:formatters_by_ft, e.g. from a .vimrc ('exrc'), like conform's
# formatters_by_ft in .nvim.lua.
const formatters_by_ft: dict<any> = {
  lua: ['stylua'],
  json: ['jq'],
  go: ['gofmt'],
  # Vim (and Neovim) detect shell scripts as "sh", never "bash".
  sh: ['shfmt'],
  typescript: ['eslint_d', 'prettier'],
  typescriptreact: ['eslint_d', 'prettier'],
  vue: ['eslint_d', 'prettier'],
  yaml: ['yq'],
  python: ['black'],
  javascript: {first: ['prettierd', 'prettier']},
}

def Available(names: list<string>): list<string>
  return names->copy()->filter((_, n) => executable(formatters[n][0]) == 1)
enddef

# Run "name" on "lines"; returns the formatted lines, or null on failure.
def Run(name: string, lines: list<string>): list<string>
  var shiftwidth = string(min([shiftwidth(), 7]))
  var cmd = formatters[name]->mapnew((_, a) => a
    ->substitute('\$FILENAME', escape(expand('%:p'), '\&'), 'g')
    ->substitute('\$SHIFTWIDTH', shiftwidth, 'g'))
  if name == 'shfmt' && &expandtab && findfile('.editorconfig', expand('%:p:h') .. ';')->empty()
    cmd += ['-i', string(shiftwidth())]
  endif
  # Like conform, only stdout is the result: stderr (e.g. the JVM's "Picked up
  # JDK_JAVA_OPTIONS" note) is only shown when the formatter fails.
  var errfile = tempname()
  var out = systemlist(cmd->mapnew((_, a) => shellescape(a))->join(' ') .. ' 2>' .. shellescape(errfile), lines)
  var err = filereadable(errfile) ? readfile(errfile) : []
  delete(errfile)
  if v:shell_error != 0
    echohl WarningMsg | echomsg $'{name} failed: {(out + err)->join(" ")}' | echohl None
    return null_list
  endif
  return out
enddef

def Format()
  if get(g:, 'disable_autoformat', false) || get(b:, 'disable_autoformat', false) || !&modifiable
    return
  endif
  # Like conform, a compound filetype ("yaml.github-actions") uses its parts.
  var by_ft = formatters_by_ft->extendnew(get(g:, 'formatters_by_ft', {}))
  var ft = &filetype->split('\.')->insert(&filetype)
    ->filter((_, f) => by_ft->has_key(f))->get(0, '')
  var config = by_ft->get(ft, [])
  var names = type(config) == v:t_dict ? Available(config.first)[: 0] : Available(config)
  if names->empty()
    if !lspbuf.BufLspServerGet(bufnr(), 'documentFormatting')->empty()
      LspFormat
    endif
    return
  endif

  var lines = getline(1, '$')
  for name in names
    var result = Run(name, lines)
    if result == null_list
      return
    endif
    lines = result
  endfor
  if lines != getline(1, '$')
    var view = winsaveview()
    setline(1, lines)
    if line('$') > len(lines)
      deletebufline('%', len(lines) + 1, '$')
    endif
    winrestview(view)
  endif
enddef

augroup kzx_format_on_save
  autocmd!
  autocmd BufWritePre * Format()
augroup END

nnoremap <leader>tff <ScriptCmd>b:disable_autoformat = !get(b:, 'disable_autoformat', false)<CR>
