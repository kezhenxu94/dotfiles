vim9script
# TypeScript (vtsls), compared with the Neovim config's behaviour.
import './helper.vim' as h

def Project(): string
  for f in ['a.ts', 'point.ts', 'tsconfig.json']
    h.Scratch($'ts/{f}')
  endfor
  return $'{$VIM_TEST_TMP}/ts'
enddef

def Open(file: string): bool
  if !executable('vtsls')
    return false
  endif
  execute $'edit {Project()}/{file}'
  if !h.Servers()->empty() && !lsp#buffer#CurbufGetServers()[0].running
    # An earlier test crashed the shared server (see Test_SwitchingFiles...).
    LspServer restart
  endif
  # The first diagnostics mean the project is loaded.
  return h.WaitForServers(['vtsls']) && h.WaitForDiags((d) => !d->empty())
enddef

# Type "keys" one at a time in Insert mode, as a user would (so the completion
# a key triggers runs before the next key); returns the completion words seen
# after each key.
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

def g:Test_ServerAttaches()
  if !Open('a.ts') | return | endif
  assert_equal(['vtsls'], h.Servers())
enddef

def g:Test_Diagnostics()
  if !Open('a.ts') | return | endif
  assert_equal([[16, "Type 'number' is not assignable to type 'string'."]],
    lsp#diag#GetDiagsForBuf()->mapnew((_, d) => [d.range.start.line + 1, d.message]))
enddef

def g:Test_CompletionAfterDot()
  if !Open('a.ts') | return | endif
  cursor(11, 1)
  # "." pops up the menu; "or" filters it; <C-n> inserts the first match.
  var log = Type('Othis', ['.', 'o', 'r', "\<C-n>"])
  assert_true(log[2]->len() > 0, 'menu after "."')
  # Neovim: "this.origin"; Vim inserts the server's textEdit text (".origin",
  # which replaces the ".") after the ".".
  assert_equal('    this.origin', getline(11))
enddef

def g:Test_AutoImportCompletion()
  if !Open('a.ts') | return | endif
  append('$', 'export const p = makePo')
  cursor(line('$'), 1)
  Type('A', ["\<C-x>\<C-o>", "\<C-n>"])
  assert_equal('export const p = makePoint', getline('$'))
  assert_match("^import { makePoint, Point } from './point';$\\|^import { Point, makePoint } from './point';$", getline(1))
enddef

def g:Test_Hover()
  if !Open('a.ts') | return | endif
  cursor(4, 12)
  h.Feed('K')
  h.WaitFor(() => PopupText() =~ 'interface Point', 'hover popup')
  popup_clear()
enddef

def g:Test_SwitchingFilesKeepsServerRunning()
  # Runs last (alphabetically): it used to kill the shared vtsls.
  if !Open('a.ts') | return | endif
  # <C-]> on "Point" opens point.ts in a new buffer.
  cursor(4, 12)
  h.Feed("\<C-]>")
  assert_equal('point.ts', expand('%:t'))
  assert_equal([1, 18], h.Pos())
  h.WaitForServers(['vtsls'])
  sleep 2
  # Vim sends a full-text didChange right after didOpen (incrementalSync is
  # off); vtsls turns it into an out-of-range edit and tsserver crashes.
  assert_true(lsp#buffer#CurbufGetServers()[0].running, 'vtsls still running')
enddef
