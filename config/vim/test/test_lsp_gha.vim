vim9script
# GitHub Actions workflows: gh_actions_ls + yamlls, compared with Neovim on
# the skywalking clones' .github/workflows. (yamlls' hover/validation for
# workflows needs the schema store, so only gh_actions_ls is tested here.)
import './helper.vim' as h

const workflow = 'gha/.github/workflows/ci.yml'

def Open(path = h.Fixture(workflow)): bool
  if !executable('gh-actions-language-server') || !executable('yaml-language-server')
    return false
  endif
  execute $'edit {path}'
  return h.WaitForServers(['gh_actions_ls', 'yamlls'])
enddef

def PopupText(): string
  return popup_list()->filter((_, id) => popup_getpos(id).visible)
    ->mapnew((_, id) => getbufline(winbufnr(id), 1, '$')->join("\n"))->join("\n")
enddef

def g:Test_GhaBothServersAttach()
  if !Open() | return | endif
  assert_equal(['gh_actions_ls', 'yamlls'], h.Servers()->sort())
  # Neovim's root_dir for gh_actions_ls is the workflows directory.
  var server = lsp#buffer#CurbufGetServers()->filter((_, s) => s.name == 'gh_actions_ls')[0]
  assert_equal([fnamemodify(h.Fixture(workflow), ':h') .. '/'], server.workspaceFolders)
enddef

def g:Test_GhaDiagnostics()
  if !Open(h.Scratch(workflow)) | return | endif
  setline(5, '    runs-onx: ubuntu-latest')
  if !h.WaitForDiags((d) => d->copy()->filter((_, x) => x.message =~ 'runs-onx')->len() > 0) | return | endif
  var diags = lsp#diag#GetDiagsForBuf()
  assert_true(diags->copy()->filter((_, d) => d.message =~ "Unexpected value 'runs-onx'"
    && d.range.start.line == 4)->len() > 0, string(diags))
  assert_true(diags->copy()->filter((_, d) => d.message =~ 'Required property is missing: runs-on')->len() > 0,
    string(diags))
enddef

def g:Test_GhaHover()
  if !Open() | return | endif
  cursor(5, 5)
  h.Feed('K')
  h.WaitFor(() => PopupText() =~ 'runner', 'hover popup')
  assert_match('type of machine to run the job on', PopupText())
  popup_clear()
enddef

# Type "keys" in Insert mode below "lnum", then (after ending any completion)
# "trigger", and return the completion words once completion offers "want"
# (Insert mode then ends).
def Complete(lnum: number, keys: string, trigger: string, want: string, timeout = 20000): list<string>
  var words: list<string>
  var start = reltime()
  var typed = false
  timer_start(50, (t) => {
    var elapsed = reltime(start)->reltimefloat() * 1000
    if !typed && elapsed > 1000
      feedkeys((complete_info(['mode']).mode != '' ? "\<C-e>" : '') .. trigger, 't')
      typed = true
      return
    endif
    # The menu itself may not fit on the test screen, so ask complete_info().
    var info = complete_info(['mode', 'items'])
    var items = info.mode == 'omni' ? info.items->mapnew((_, i) => i.word) : []
    if items->index(want) >= 0 || elapsed > timeout
      words = items
      timer_stop(t)
      feedkeys("\<C-e>\<Esc>", 't')
    endif
  }, {repeat: -1})
  cursor(lnum, 1)
  feedkeys($"o{keys}", 'xt!')
  return words
enddef

def g:Test_GhaCompletionAfterDot()
  if !Open(h.Scratch(workflow)) | return | endif
  # gh_actions_ls answers with nothing until it has parsed the workflow; a
  # hover result on "runs-on" means it has.
  var server = lsp#buffer#CurbufGetServer('hover')
  if !h.WaitFor(() => type(server.rpc('textDocument/hover', {
      textDocument: {uri: lsp#util#LspBufnrToUri(bufnr())},
      position: {line: 4, character: 5}})->get('result', v:null)) == v:t_dict,
      'gh_actions_ls parsed the workflow')
    return
  endif
  var words = Complete(8, 'working-directory: ${{ github', '.', 'sha')
  assert_true(words->index('sha') >= 0 && words->index('ref') >= 0, string(words))
enddef
