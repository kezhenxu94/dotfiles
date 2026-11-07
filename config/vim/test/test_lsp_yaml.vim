vim9script
# yaml-language-server on plain YAML and docker compose files: compared with
# Neovim on the skywalking clones. Format on save (yq/jq) is covered by
# test_formatter.vim, filetype detection by test_filetypes.vim.
import './helper.vim' as h

def Open(path: string): bool
  if !executable('yaml-language-server')
    return false
  endif
  execute $'edit {h.Fixture(path)}'
  return h.WaitForServers(['yamlls'])
enddef

def g:Test_YamlOnlyYamllsAttaches()
  if !Open('yaml/config.yaml') | return | endif
  assert_equal('yaml', &filetype)
  assert_equal(['yamlls'], h.Servers())
enddef

def g:Test_ComposeOnlyYamllsAttaches()
  # Both editors keep compose files as plain "yaml", so docker_language_server
  # (yaml.docker-compose) does not attach.
  if !Open('yaml/docker-compose.yml') | return | endif
  assert_equal('yaml', &filetype)
  assert_equal(['yamlls'], h.Servers())
enddef

def g:Test_YamlDiagnostics()
  if !Open('yaml/dup.yaml') | return | endif
  if !h.WaitForDiags((d) => !d->empty()) | return | endif
  var diags = lsp#diag#GetDiagsForBuf()
  assert_equal([[2, 1]], diags->mapnew((_, d) => [d.range.start.line + 1, d.severity]))
  assert_match('Map keys must be unique', diags[0].message)
  assert_equal(['LspDiagVirtualTextError'],
    prop_list(2)->mapnew((_, p) => p.type)->filter((_, t) => t =~ 'VirtualText'))
  cursor(1, 1)
  h.Feed(']d')
  assert_equal([2, 1], h.Pos())
enddef

def g:Test_YamlFolds()
  if !Open('yaml/config.yaml') | return | endif
  h.WaitFor(() => &foldmethod == 'expr', 'folds from foldingRange')
  # Same levels as Neovim's tree-sitter folds.
  assert_equal([1, 1, 1, 1, 1, 2, 2], range(1, line('$'))->mapnew((_, l) => foldlevel(l)))
enddef

def g:Test_YamlNoFunctionOrClassMotions()
  # nvim-treesitter-textobjects has no @function/@class captures for YAML, so
  # ]m and ]c do not move in Neovim.
  if !Open('yaml/config.yaml') || !h.WaitForSymbols() | return | endif
  for keys in [']m', ']c', ']M']
    cursor(1, 1)
    h.Feed(keys)
    assert_equal([1, 1], h.Pos(), keys)
  endfor
enddef
