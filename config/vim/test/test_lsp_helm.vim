vim9script
# helm_ls on chart templates (vim-helm's "helm" filetype), compared with
# Neovim on the skywalking-helm/skywalking-kubernetes charts. values.yaml is
# plain "yaml" in both editors (vim-helm's "setfiletype yaml.helm-values"
# comes after the builtin detection), so helm_ls never attaches to it.
import './helper.vim' as h

const template = 'helm/chart/templates/svc.yaml'

# Open the template (a scratch copy of the whole chart when "scratch" is set)
# and wait until helm_ls has loaded the chart: a hover result on
# ".Values.service.type" means it has.
def Open(scratch = false): bool
  if !executable('helm_ls')
    return false
  endif
  var path = h.Fixture(template)
  if scratch
    h.Scratch('helm/chart/Chart.yaml')
    h.Scratch('helm/chart/values.yaml')
    path = h.Scratch(template)
  endif
  execute $'edit {path}'
  if !h.WaitForServers(['helm_ls'])
    return false
  endif
  var server = lsp#buffer#CurbufGetServer('hover')
  return h.WaitFor(() => type(server.rpc('textDocument/hover', {
    textDocument: {uri: lsp#util#LspBufnrToUri(bufnr())},
    position: {line: 5, character: 28}})->get('result', v:null)) == v:t_dict,
    'helm_ls loaded the chart', 30000)
enddef

def PopupText(): string
  return popup_list()->filter((_, id) => popup_getpos(id).visible)
    ->mapnew((_, id) => getbufline(winbufnr(id), 1, '$')->join("\n"))->join("\n")
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

def g:Test_HelmServers()
  if !Open() | return | endif
  assert_equal('helm', &filetype)
  assert_equal(['helm_ls'], h.Servers())
  if !executable('yaml-language-server') | return | endif
  execute $'edit {h.Fixture('helm/chart/values.yaml')}'
  h.WaitForServers(['yamlls'])
  assert_equal('yaml', &filetype)
  assert_equal(['yamlls'], h.Servers())
enddef

def g:Test_HelmHoverShowsValue()
  if !Open() | return | endif
  cursor(6, 1)
  search('service\.\zstype')
  h.Feed('K')
  h.WaitFor(() => PopupText() =~ 'ClusterIP', 'hover popup')
  assert_match('values.yaml\n\nClusterIP$', PopupText())
  popup_clear()
enddef

def g:Test_HelmDefinitionJumpsToValues()
  if !Open() | return | endif
  cursor(6, 1)
  search('service\.\zstype')
  h.Feed("\<C-]>")
  assert_equal(h.Fixture('helm/chart/values.yaml'), expand('%:p'))
  assert_equal(2, line('.'))
enddef

def g:Test_HelmCompletionAfterDot()
  if !Open(true) | return | endif
  var words = Complete(6, '  x: {{ .Values.service', '.', 'port')
  assert_equal(['port', 'type'], words->copy()->sort())
enddef

def g:Test_HelmKeepsIndent()
  # Neovim indents with tree-sitter; with the global 'cindent' Vim treats
  # "key:" as a C label and moves it to column 1.
  if !Open(true) | return | endif
  cursor(6, 1)
  h.Feed("ox: 1\<Esc>")
  assert_equal('  x: 1', getline(7))
enddef

def g:Test_HelmFoldsFollowYamlStructure()
  execute $'edit {h.Fixture('helm/chart/templates/deploy.yaml')}'
  assert_equal('helm', &filetype)
  # Neovim's tree-sitter levels for this file (it differs only below
  # "env:", whose value is a template action).
  assert_equal([0, 0, 1, 1, 1, 1, 1, 1, 2, 3, 4, 4, 5, 5],
    range(1, 14)->mapnew((_, l) => foldlevel(l)))
enddef
