vim9script
# docker-language-server on a Dockerfile: compared with Neovim on
# fixtures/docker/Dockerfile. (Its inlay hints and image hovers query Docker
# Hub, so they are not tested here.)
import './helper.vim' as h

def Open(): bool
  if !executable('docker-language-server')
    return false
  endif
  execute $'edit {h.Scratch('docker/Dockerfile')}'
  return h.WaitForServers(['docker_language_server'])
    && h.WaitForDiags((d) => len(d) == 2)
enddef

def Mapped(start: list<number>, keys: string): list<number>
  cursor(start)
  h.Feed(keys)
  return h.Pos()
enddef

def g:Test_DockerOnlyDockerLanguageServerAttaches()
  if !Open() | return | endif
  assert_equal('dockerfile', &filetype)
  assert_equal(['docker_language_server'], h.Servers())
enddef

def g:Test_DockerBuildCheckDiagnostics()
  if !Open() | return | endif
  var diags = lsp#diag#GetDiagsForBuf()
    ->mapnew((_, d) => [d.range.start.line + 1, d.range.start.character + 1, d.severity])
    ->sort()
  # FromAsCasing and JSONArgsRecommended warnings.
  assert_equal([[1, 1, 2], [6, 1, 2]], diags)
  assert_equal(['LspDiagVirtualTextWarning'],
    prop_list(6)->mapnew((_, p) => p.type)->filter((_, t) => t =~ 'VirtualText'))
  assert_equal([6, 1], Mapped([2, 1], ']d'))
  assert_equal([1, 1], Mapped([2, 1], '[d'))
enddef

def g:Test_DockerCodeAction()
  if !Open() | return | endif
  cursor(1, 15)
  # The only action: skip the FromAsCasing check.
  LspCodeAction 1
  h.WaitFor(() => getline(1) =~ 'check=skip=FromAsCasing', 'code action applied')
enddef

def g:Test_DockerNoFoldsOrFormatter()
  if !Open() | return | endif
  # Neither tree-sitter nor the server folds a Dockerfile.
  assert_equal(repeat([0], line('$')), range(1, line('$'))->mapnew((_, l) => foldlevel(l)))
  # No formatter: saving keeps the buffer as is.
  setline(2, 'RUN    echo hi')
  silent write
  assert_equal('RUN    echo hi', readfile(expand('%'))[1])
enddef
