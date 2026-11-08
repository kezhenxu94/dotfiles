vim9script
# bash-language-server (with shellcheck) and shfmt: compared with Neovim
# (tree-sitter + vim.lsp) on fixtures/sh/script.sh.
import './helper.vim' as h

def Open(): bool
  if !executable('bash-language-server')
    return false
  endif
  execute $'edit {h.Scratch('sh/script.sh')}'
  return h.WaitForServers(['bashls'])
enddef

def Mapped(start: list<number>, keys: string): list<number>
  cursor(start)
  h.Feed(keys)
  return h.Pos()
enddef

def Moves(start: list<number>, keys: string, n: number): list<list<number>>
  cursor(start)
  return range(n)->mapnew((_, _) => {
    h.Feed(keys)
    return h.Pos()
  })
enddef

def Selected(start: list<number>, keys: string): list<list<number>>
  cursor(start)
  h.Feed($"{keys}\<Esc>")
  return [getpos("'<")[1 : 2], getpos("'>")[1 : 2]]
enddef

def PopupText(): string
  return popup_list()->mapnew((_, w) => getbufline(winbufnr(w), 1, '$')->join("\n"))->join("\n")
enddef

def g:Test_ShOnlyBashlsAttaches()
  if !Open() | return | endif
  assert_equal('sh', &filetype)
  assert_equal(['bashls'], h.Servers())
enddef

def g:Test_ShShellcheckDiagnostics()
  if !Open() || !executable('shellcheck') | return | endif
  h.WaitForDiags((d) => !d->empty())
  var diags = lsp#diag#GetDiagsForBuf()
    ->mapnew((_, d) => [d.range.start.line + 1, d.range.start.character + 1, d.severity, d.code])
  assert_equal([[9, 10, 3, 'SC2086']], diags)
  assert_equal(['LspDiagVirtualTextInfo'],
    prop_list(9)->mapnew((_, p) => p.type)->filter((_, t) => t =~ 'VirtualText'))
  assert_equal([9, 10], Mapped([1, 1], ']d'))
  assert_equal([9, 10], Mapped([20, 1], '[d'))
  # shellcheck's SC2086 quickfix is the first code action.
  cursor(9, 10)
  LspCodeAction 1
  h.WaitFor(() => getline(9) == '  rm -rf "$1"', 'code action applied')
enddef

# Type "keys" after line 4; while Vim stays in Insert mode each step
# [Probe, keys] waits for Probe() and then types "keys".
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
  cursor(4, 1)
  feedkeys($"o{keys}", 'xt!')
  if !ok
    v:errors->add($'Timed out at step {i + 1} after typing {string(keys)}')
  endif
  return ok
enddef

def g:Test_ShCompletionOnDollar()
  if !Open() | return | endif
  var words: list<string>
  Type('echo $', [
    [() => !complete_info(['items']).items->empty(), ''],
    [() => {
      words = complete_info(['items']).items->mapnew((_, i) => i.word)
      return true
    }, "\<C-n>\<CR>"],
  ])
  assert_equal(['name'], words)
  assert_equal('  echo $name', getline(5))
enddef

def g:Test_ShHoverAndDefinition()
  if !Open() | return | endif
  cursor(14, 5)
  h.Feed('K')
  h.WaitFor(() => !popup_list()->empty(), 'hover popup')
  assert_match('Function: greet - defined on line 3', PopupText())
  popup_clear()
  assert_equal([3, 1], Mapped([14, 5], "\<C-]>"))
enddef

def g:Test_ShRename()
  if !Open() | return | endif
  cursor(14, 5)
  h.Feed("grn\<C-u>hello\<CR>")
  assert_equal('hello() {', getline(3))
  assert_equal('    hello "$1"', getline(14))
  assert_equal('    hello world', getline(16))
enddef

# Neovim lists references in the quickfix list.
def g:Test_ShReferencesInQuickfix()
  if !Open() | return | endif
  # Leave room for the list window under the tall cmdheight of helper.vim.
  set cmdheight=18
  defer execute('set cmdheight=10')
  setqflist([], 'f')
  cursor(3, 1)
  h.Feed('grr')
  h.WaitFor(() => !getqflist()->empty(), 'references in quickfix')
  assert_equal([3, 14, 16], getqflist()->mapnew((_, i) => i.lnum)->sort('n'))
  cclose
  lclose
enddef

# Tree-sitter folds functions and if blocks, closing lines included (bashls
# has no foldingRange).
def g:Test_ShFolds()
  if !Open() | return | endif
  assert_equal([0, 0, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, 2, 2, 2, 2, 2, 1, 1, 0, 0],
    range(1, line('$'))->mapnew((_, l) => foldlevel(l)))
enddef

def g:Test_ShFunctionMotions()
  if !Open() | return | endif
  h.WaitForSymbols()
  assert_equal([[3, 1], [8, 1], [12, 1]], Moves([1, 1], ']m', 3))
  assert_equal([[6, 1], [10, 1], [19, 1]], Moves([1, 1], ']M', 3))
  assert_equal([[8, 1], [3, 1]], Moves([12, 1], '[m', 2))
  assert_equal([8, 1], Mapped([3, 1], ']m'))
  assert_equal([12, 1], Mapped([8, 1], ';'))
  assert_equal([8, 1], Mapped([12, 1], ','))
enddef

def g:Test_ShFunctionTextobjects()
  if !Open() | return | endif
  h.WaitForSymbols()
  assert_equal([[3, 1], [6, 1]], Selected([4, 3], 'vam'))
  assert_equal([[12, 1], [19, 1]], Selected([14, 3], 'vam'))
  # Lookahead from before the first function.
  assert_equal([[3, 1], [6, 1]], Selected([1, 1], 'vam'))
enddef

# @function.inner starts at the first statement, not at its indent.
def g:Test_ShInnerFunctionStartsAtStatement()
  if !Open() | return | endif
  h.WaitForSymbols()
  assert_equal([[4, 3], [5, 21]], Selected([4, 3], 'vim'))
  assert_equal([[13, 3], [18, 16]], Selected([14, 3], 'vim'))
enddef
