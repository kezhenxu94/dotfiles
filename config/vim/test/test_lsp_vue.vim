vim9script
# Vue (vue_ls in hybrid mode + vtsls with @vue/typescript-plugin), compared
# with the Neovim config's behaviour. The fixture has no node_modules, so
# template type checking is limited, but vue_ls <-> vtsls forwarding works.
import './helper.vim' as h

def Project(): string
  for f in ['App.vue', 'Child.vue', 'package.json', 'tsconfig.json']
    h.Scratch($'vue/{f}')
  endfor
  return $'{$VIM_TEST_TMP}/vue'
enddef

def Open(): bool
  if !executable('vue-language-server') || !executable('vtsls')
    return false
  endif
  execute $'edit {Project()}/App.vue'
  if lsp#buffer#CurbufGetServers()->copy()->filter((_, s) => !s.running)->len() > 0
    LspServer restart
  endif
  return h.WaitForServers(['vue_ls', 'vtsls']) && h.WaitForDiags((d) => !d->empty())
enddef

def Server(name: string): dict<any>
  return lsp#buffer#CurbufGetServers()->copy()->filter((_, s) => s.name == name)->get(0, {})
enddef

# Same as in test_lsp_ts.vim.
def Type(start: string, keys: list<string>): list<list<string>>
  var log: list<list<string>> = []
  var todo = keys->copy()
  timer_start(500, (t) => {
    log->add(complete_info(['items']).items->mapnew((_, v) => v.word))
    if todo->empty()
      timer_stop(t)
      feedkeys("\<Esc>", 't')
    else
      feedkeys(todo->remove(0), 't')
    endif
  }, {repeat: -1})
  feedkeys(start, 'xt!')
  return log
enddef

def PopupText(): string
  return popup_list()->mapnew((_, w) => getbufline(winbufnr(w), 1, '$')->join("\n"))->join("\n")
enddef

def g:Test_ServersAttach()
  if !Open() | return | endif
  assert_equal(['vtsls', 'vue_ls'], h.Servers()->sort())
enddef

def g:Test_ScriptDiagnosticsFromVtsls()
  if !Open() | return | endif
  assert_equal([[8, "Type 'number' is not assignable to type 'string'."]],
    lsp#diag#GetDiagsForBuf()->copy()->filter((_, d) => d.range.start.line == 7)
      ->mapnew((_, d) => [d.range.start.line + 1, d.message]))
enddef

def g:Test_TsserverRequestsAreForwarded()
  if !Open() | return | endif
  # vue_ls asks tsserver (through vtsls) for the components and bindings the
  # template can use; count the requests it sends.
  var vue = Server('vue_ls')
  var Orig = vue.customNotificationHandlers['tsserver/request']
  var forwarded = 0
  vue.customNotificationHandlers['tsserver/request'] = (s, n) => {
    forwarded += 1
    Orig(s, n)
  }
  try
    var result = vue.rpc('textDocument/completion', {
      textDocument: {uri: lsp#util#LspBufnrToUri(bufnr())},
      position: {line: 11, character: 3}, context: {triggerKind: 1}}, {timeout: 10000})
    var labels = result->get('result', {})->get('items', [])->mapnew((_, v) => v.label)
    assert_true(forwarded > 0, 'tsserver/request forwarded')
    assert_true(labels->index('Child') >= 0, $'imported component completed: {labels[: 20]}')
    assert_true(labels->index('increment') >= 0, $'setup binding completed: {labels[: 20]}')
  finally
    vue.customNotificationHandlers['tsserver/request'] = Orig
  endtry
enddef

def g:Test_DirectiveCompletion()
  if !Open() | return | endif
  append(12, '  <p v-i')
  # Pick "v-if" from the menu, like a user would.
  cursor(13, 1)
  var log = Type('A', ["\<C-x>\<C-o>"])
  var n = log[-1]->match('^\(v-\)\=if\(=""\)\=$')
  assert_true(n >= 0, $'v-if offered: {log[-1][: 10]}')
  setline(13, '  <p v-i')
  cursor(13, 1)
  Type('A', ["\<C-x>\<C-o>"] + repeat(["\<C-n>"], n + 1))
  # Neovim: <p v-if="" (the snippet's $1 placeholder is expanded).
  assert_equal('  <p v-if=""', getline(13))
enddef

def g:Test_CompletionInScriptSetup()
  if !Open() | return | endif
  cursor(7, 1)
  # Neovim merges vtsls' items; Vim only asks vue_ls, which has none here.
  var log = Type('ocount', ['.', 't', 'o', 'F'])
  assert_true(log[1]->index('toFixed') >= 0 || log[1]->index('.toFixed') >= 0, $'menu after ".": {log[1][: 10]}')
enddef

def g:Test_HoverInTemplate()
  if !Open() | return | endif
  cursor(12, 19)
  h.Feed('K')
  # Neovim shows vtsls' "function increment(step: number): number".
  h.WaitFor(() => PopupText() =~ 'increment', 'hover popup', 5000)
  popup_clear()
enddef

def g:Test_DefinitionFromTemplate()
  if !Open() | return | endif
  cursor(12, 19)
  try
    h.Feed("\<C-]>")
  catch /E426:\|E433:/
  endtry
  # Neovim jumps to "function increment" in the script.
  assert_equal([5, 10], h.Pos())
enddef
