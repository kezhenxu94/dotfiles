vim9script
# gopls: compared with Neovim (tree-sitter + vim.lsp) on fixtures/go.
import './helper.vim' as h

# Copy the module to the scratch dir and open "file" in it, with gopls ready
# and the package loaded (gopls answers with nothing before that).
def Open(file: string): bool
  if !executable('gopls')
    return false
  endif
  for f in ['go.mod', 'main.go', 'bad/bad.go']
    h.Scratch($'go/{f}')
  endfor
  execute $'edit {$VIM_TEST_TMP}/go/{file}'
  if !h.WaitForServers(['gopls'])
    return false
  endif
  var server = lsp#buffer#CurbufGetServer('hover')
  return h.WaitFor(() => type(server.rpc('textDocument/hover', {
    textDocument: {uri: lsp#util#LspBufnrToUri(bufnr())},
    position: {line: 2, character: 8}})->get('result', v:null)) == v:t_dict,
    'gopls loaded the package', 60000)
enddef

def Mapped(start: list<number>, keys: string): list<number>
  cursor(start)
  h.Feed(keys)
  return h.Pos()
enddef

# Positions after pressing "keys" n times from "start".
def Moves(start: list<number>, keys: string, n: number): list<list<number>>
  cursor(start)
  return range(n)->mapnew((_, _) => {
    h.Feed(keys)
    return h.Pos()
  })
enddef

# Visual selection [start, end] made by "keys" (e.g. "vam") from "start".
def Selected(start: list<number>, keys: string): list<list<number>>
  cursor(start)
  h.Feed($"{keys}\<Esc>")
  return [getpos("'<")[1 : 2], getpos("'>")[1 : 2]]
enddef

def BuiltinFoldLevels(): list<number>
  return range(1, line('$'))->mapnew((_, l) => foldlevel(l))
enddef

def g:Test_GoOnlyGoplsAttaches()
  if !Open('main.go') | return | endif
  assert_equal(['gopls'], h.Servers())
  execute $'edit {$VIM_TEST_TMP}/go/go.mod'
  assert_equal('gomod', &filetype)
  h.WaitForServers(['gopls'])
  assert_equal(['gopls'], h.Servers())
enddef

def g:Test_GoDiagnostics()
  if !Open('bad/bad.go') | return | endif
  h.WaitForDiags((d) => len(d) == 2)
  var diags = lsp#diag#GetDiagsForBuf()
    ->mapnew((_, d) => [d.range.start.line + 1, d.range.start.character + 1, d.severity])
    ->sort()
  # printf (warning) and the rangeint modernizer (hint).
  assert_equal([[6, 14, 2], [7, 6, 4]], diags)
  assert_equal(['LspDiagVirtualTextWarning'],
    prop_list(6)->mapnew((_, p) => p.type)->filter((_, t) => t =~ 'VirtualText'))
  assert_equal('WarningMsg', sign_getdefined('LspDiagWarning')[0]->get('numhl', ''))
  assert_equal([6, 14], Mapped([1, 1], ']d'))
  assert_equal([7, 6], Mapped([6, 14], ']d'))
  assert_equal([6, 14], Mapped([7, 6], '[d'))
  assert_equal([7, 6], Mapped([1, 1], '2]d'))
  # No errors: ]e and [e stay put.
  assert_equal([1, 1], Mapped([1, 1], ']e'))
  assert_equal([8, 1], Mapped([8, 1], '[e'))
enddef

def g:Test_GoDiagnosticLists()
  if !Open('bad/bad.go') | return | endif
  set cmdheight=18
  defer execute('set cmdheight=10')
  h.WaitForDiags((d) => len(d) == 2)
  h.Feed(' sd')
  assert_equal([6, 7], getloclist(0)->mapnew((_, i) => i.lnum)->sort('n'))
  lclose
  h.Feed(' sD')
  assert_equal([6, 7], getqflist()->mapnew((_, i) => i.lnum)->sort('n'))
  cclose
  cursor(6, 14)
  h.Feed(' de')
  assert_match('wrong type string', popup_list()
    ->mapnew((_, w) => getbufline(winbufnr(w), 1, '$')->join("\n"))->join("\n"))
  popup_clear()
enddef

# Type "keys" after line 20; while Vim stays in Insert mode each step
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
  cursor(20, 1)
  feedkeys($"o{keys}", 'xt!')
  if !ok
    v:errors->add($'Timed out at step {i + 1} after typing {string(keys)}')
  endif
  return ok
enddef

def Words(): list<string>
  return complete_info(['matches']).matches->mapnew((_, i) => i.abbr->matchstr('^\k\+'))
enddef

def g:Test_GoCompletionAddsImport()
  if !Open('main.go') | return | endif
  Type("strings.", [
    [() => !complete_info(['items']).items->empty(), 'TrimSpa'],
    [() => Words()->get(0, '') == 'TrimSpace', "\<C-n>\<CR>"],
  ])
  assert_match('^\tstrings\.TrimSpace', getline(24))
  assert_equal(['import (', "\t\"fmt\"", "\t\"strings\"", ')'], getline(3, 6))
enddef

def g:Test_GoHover()
  if !Open('main.go') | return | endif
  cursor(19, 8)
  h.Feed('K')
  h.WaitFor(() => !popup_list()->empty(), 'hover popup')
  assert_match('type Greeter interface', popup_list()
    ->mapnew((_, w) => getbufline(winbufnr(w), 1, '$')->join("\n"))->join("\n"))
  popup_clear()
enddef

def g:Test_GoDefinitionAndTypeDefinition()
  if !Open('main.go') | return | endif
  # <C-]> goes through tagfunc.
  assert_equal([10, 6], Mapped([19, 18], "\<C-]>"))
  assert_equal([19, 18], Mapped([10, 6], "\<C-t>"))
  assert_equal([6, 6], Mapped([19, 6], 'grt'))
enddef

# Neovim always lists implementations and references in the quickfix list
# (no jump, even for a single result).
def g:Test_GoImplementationInQuickfix()
  if !Open('main.go') | return | endif
  # Leave room for the list window under the tall cmdheight of helper.vim.
  set cmdheight=18
  defer execute('set cmdheight=10')
  setqflist([], 'f')
  assert_equal([6, 6], Mapped([6, 6], 'gri'))
  h.WaitFor(() => !getqflist()->empty(), 'implementations in quickfix')
  assert_equal([[10, 6]], getqflist()->mapnew((_, i) => [i.lnum, i.col]))
  cclose
enddef

def g:Test_GoReferencesInQuickfix()
  if !Open('main.go') | return | endif
  # Leave room for the list window under the tall cmdheight of helper.vim.
  set cmdheight=18
  defer execute('set cmdheight=10')
  setqflist([], 'f')
  cursor(20, 16)
  h.Feed('grr')
  h.WaitFor(() => !getqflist()->empty(), 'references in quickfix')
  assert_equal([7, 20], getqflist()->mapnew((_, i) => i.lnum)->sort('n'))
  cclose
  lclose
enddef

def g:Test_GoRename()
  if !Open('main.go') | return | endif
  cursor(10, 6)
  h.Feed("grn\<C-u>british\<CR>")
  assert_equal(['type british struct {'], getline(10, 10))
  assert_match('^func (e british) Greet', getline(14))
  assert_match('= british{', getline(19))
enddef

def g:Test_GoCodeAction()
  if !Open('bad/bad.go') | return | endif
  h.WaitForDiags((d) => len(d) == 2)
  cursor(7, 6)
  # gra runs :LspCodeAction; the quickfix for the rangeint hint is the first
  # action (pick it directly: the menu would wait for input).
  assert_match("LspCodeAction", maparg("gra", "n"))
  LspCodeAction 1
  h.WaitFor(() => getline(7) == "\tfor range 3 {", 'code action applied')
enddef

# Runs last (tests run in name order): saving go.mod makes gopls ask whether
# to run govulncheck (a blocking inputlist(), as in Neovim's vim.ui.select).
def g:Test_GoZzModFormatsWithGopls()
  # No conform formatter for gomod: the language server formats it.
  if !Open('main.go') | return | endif
  writefile(['module example.com/fixture', '', 'go     1.22'], $'{$VIM_TEST_TMP}/go/go.mod')
  execute $'edit {$VIM_TEST_TMP}/go/go.mod'
  h.WaitForServers(['gopls'])
  silent write
  assert_equal(['module example.com/fixture', '', 'go 1.22'], readfile(expand('%')))
enddef

# Like the tree-sitter folds: each block, including its closing brace.
def g:Test_GoFolds()
  if !Open('main.go') | return | endif
  h.WaitFor(() => exists('b:kzx_folds'), 'folds')
  assert_equal([0, 0, 0, 0, 0, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 1], BuiltinFoldLevels())
enddef

def g:Test_GoFunctionMotions()
  if !Open('main.go') | return | endif
  h.WaitForSymbols()
  assert_equal([[16, 1], [21, 1]], Moves([13, 1], ']M', 2))
  assert_equal([[18, 1], [14, 1]], Moves([21, 1], '[m', 2))
  assert_equal([14, 1], Mapped([13, 1], ']m'))
  assert_equal([18, 1], Mapped([14, 1], ';'))
  assert_equal([14, 1], Mapped([18, 1], ','))
enddef

# Interface method specs are no @function.outer in tree-sitter.
def g:Test_GoFunctionMotionsSkipInterfaceMethods()
  if !Open('main.go') | return | endif
  h.WaitForSymbols()
  assert_equal([[14, 1], [18, 1]], Moves([1, 1], ']m', 2))
  assert_equal([[14, 1], [16, 1]], Selected([1, 1], 'vam'))
enddef

# @class.outer starts at "type", not at the type's name.
def g:Test_GoClassMotionsStartAtType()
  if !Open('main.go') | return | endif
  h.WaitForSymbols()
  assert_equal([[6, 1], [10, 1]], Moves([1, 1], ']c', 2))
  assert_equal([[10, 1], [12, 1]], Selected([11, 3], 'vac'))
enddef

def g:Test_GoFunctionTextobjects()
  if !Open('main.go') | return | endif
  h.WaitForSymbols()
  assert_equal([[14, 1], [16, 1]], Selected([15, 3], 'vam'))
  assert_equal([[18, 1], [21, 1]], Selected([20, 3], 'vam'))
  # Operator-pending: dam deletes the whole method.
  cursor(15, 3)
  h.Feed('dam')
  assert_equal(['', '', '', 'func main() {'], getline(13, 16))
enddef

def g:Test_GoSemanticHighlight()
  if !Open('main.go') | return | endif
  h.WaitFor(() => prop_list(14)->len() > 0, 'semantic tokens')
  var types = prop_list(14)->mapnew((_, p) => [p.col, p.type])
  assert_true(types->index([18, 'LspSemanticMethod']) >= 0, string(types))
  assert_true(types->index([9, 'LspSemanticType']) >= 0, string(types))
enddef
