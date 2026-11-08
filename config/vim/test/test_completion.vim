vim9script
# LSP completion pops up on the server's trigger characters (like
# vim.lsp.completion's autotrigger) and filters as you type, but not on
# every keystroke.
import './helper.vim' as h

def Setup(): bool
  if !executable('gopls')
    return false
  endif
  execute $'edit {h.Scratch('completion/go.mod')->fnamemodify(':h')}/main.go'
  writefile(readfile(h.Fixture('completion/main.go')), expand('%'))
  edit!
  if !h.WaitForServers(['gopls'])
    return false
  endif
  # gopls answers completion with nothing until the package is loaded; a
  # hover result on fmt.Println (line 14) means it is.
  var server = lsp#buffer#CurbufGetServer('hover')
  return h.WaitFor(() => type(server.rpc('textDocument/hover', {
    textDocument: {uri: lsp#util#LspBufnrToUri(bufnr())},
    position: {line: 13, character: 6}})->get('result', v:null)) == v:t_dict,
    'gopls loaded the package', 60000)
enddef

# Type "keys" in Insert mode after line 13. While Vim stays in Insert mode,
# each step [Probe, keys] waits for Probe() and then types "keys"; Insert
# mode ends after the last step (or on timeout). Returns false on timeout.
def Type(keys: string, steps: list<list<any>>, timeout = 20000): bool
  var i = 0
  var start = reltime()
  var ok = false
  timer_start(50, (t) => {
    if i < len(steps) && steps[i][0]()
      feedkeys(steps[i][1], 't')
      i += 1
    endif
    ok = i == len(steps)
    if ok || reltime(start)->reltimefloat() * 1000 > timeout
      timer_stop(t)
      feedkeys("\<Esc>", 't')
    endif
  }, {repeat: -1})
  cursor(13, 1)
  feedkeys($"o{keys}", 'xt!')
  if !ok
    v:errors->add($'Timed out at step {i + 1} after typing {string(keys)}')
  endif
  return ok
enddef

# Names of the menu entries left after filtering by the typed text (the
# inserted words carry snippet text such as "Start()").
def Words(): list<string>
  return complete_info(['matches']).matches->mapnew((_, i) => i.abbr->matchstr('^\k\+'))
enddef

def g:Test_PopsUpOnTriggerCharacter()
  if !Setup() | return | endif
  var words: list<string>
  Type("srv.", [[() => pumvisible() == 1, ''], [() => {
    words = Words()->sort()
    return true
  }, '']])
  assert_equal(['Address', 'Name', 'Start'], words)
enddef

def g:Test_FiltersWhileTyping()
  if !Setup() | return | endif
  Type("srv.", [
    [() => pumvisible() == 1, 'St'],
    [() => Words() == ['Start'], "\<C-n>\<CR>"],
  ])
  # The snippet "Start()" is inserted as plain text.
  assert_equal("\tsrv.Start()", getline(14), '<CR> accepts the item')
enddef

def g:Test_NoPopupOnPlainWords()
  if !Setup() | return | endif
  var start = reltime()
  var seen = false
  Type("sr", [[() => {
    seen = seen || pumvisible() == 1
    return reltime(start)->reltimefloat() > 1.5
  }, '']])
  assert_false(seen, 'no popup without a trigger character')
enddef

def g:Test_MenuShowsFullKindNames()
  if !Setup() | return | endif
  var kinds: list<string>
  Type("srv.", [[() => pumvisible() == 1, ''], [() => {
    kinds = complete_info(['items']).items->mapnew((_, i) => i.kind)->sort()->uniq()
    return true
  }, '']])
  assert_equal(['Field', 'Method'], kinds)
enddef
