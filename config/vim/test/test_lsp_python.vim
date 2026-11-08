vim9script
# pyright (+ black): compared with Neovim (tree-sitter + vim.lsp) on
# fixtures/python. The expected values are what Neovim does.
import './helper.vim' as h

def Open(): bool
  if !executable('pyright-langserver')
    return false
  endif
  execute $'edit {h.Fixture('python/a.py')}'
  return h.WaitForServers(['pyright'])
enddef

def Mapped(start: list<number>, keys: string): list<number>
  cursor(start)
  h.Feed(keys)
  return h.Pos()
enddef

# Visual selection [start, end, mode] made by "keys" (e.g. "vam") from "start".
def Selected(start: list<number>, keys: string): list<any>
  cursor(start)
  h.Feed($"{keys}\<Esc>")
  return [getpos("'<")[1 : 2], getpos("'>")[1 : 2], visualmode()]
enddef

def g:Test_PythonOnlyPyrightAttaches()
  if !Open() | return | endif
  assert_equal(['pyright'], h.Servers())
enddef

def g:Test_PythonDiagnostics()
  if !Open() | return | endif
  h.WaitForDiags((d) => !d->empty())
  var diags = lsp#diag#GetDiagsForBuf()
  assert_equal([23], diags->mapnew((_, d) => d.range.start.line))
  assert_match('"Literal\[''oops''\]" is not assignable to declared type "int"', diags[0].message)
  assert_equal([24, 14], Mapped([1, 1], ']e'))
  assert_equal([24, 14], Mapped([25, 1], '[d'))
enddef

def g:Test_PythonHoverAndDefinition()
  if !Open() | return | endif
  cursor(25, 19)
  h.Feed('K')
  h.WaitFor(() => !popup_list()->empty(), 'hover popup')
  assert_match('class Greeter', popup_list()->mapnew((_, p) => getbufline(winbufnr(p), 1, '$')->join("\n"))->join("\n"))
  popup_clear()
  assert_equal([6, 5], Mapped([25, 8], "\<C-]>"))
enddef

# The python ftplugin's buffer-local ]m/[m/]M/[M win over the global
# mappings, in both editors.
def g:Test_PythonMethodMotionsFromFtplugin()
  if !Open() | return | endif
  assert_equal([10, 1], Mapped([6, 1], ']m'))
  assert_equal([11, 5], Mapped([10, 1], ']m'))
  assert_equal([7, 16], Mapped([6, 1], ']M'))
  assert_equal([6, 1], Mapped([7, 5], '[m'))
enddef

def g:Test_PythonClassMotions()
  if !Open() | return | endif
  h.WaitForSymbols()
  assert_equal([10, 1], Mapped([1, 1], ']c'))
  assert_equal([10, 1], Mapped([19, 9], '[c'))
enddef

def g:Test_PythonAroundFunction()
  if !Open() | return | endif
  h.WaitForSymbols()
  # The decorator belongs to the function only from the decorator line.
  assert_equal([[6, 1], [7, 16], 'v'], Selected([7, 5], 'vam'))
  assert_equal([[18, 5], [21, 19], 'v'], Selected([19, 9], 'vam'))
  assert_equal([[10, 1], [21, 19], 'v'], Selected([19, 9], 'vac'))
enddef

def g:Test_PythonInnerFunctionIsTheBody()
  if !Open() | return | endif
  h.WaitForSymbols()
  # Not the parameters of a multi-line signature, nor the "def" line of a
  # decorated function.
  assert_equal([[15, 9], [15, 24], 'v'], Selected([12, 9], 'vim'))
  assert_equal([[19, 9], [21, 19], 'v'], Selected([17, 5], 'vim'))
  assert_equal([[7, 5], [7, 16], 'v'], Selected([6, 1], 'vim'))
  assert_equal([[11, 5], [21, 19], 'v'], Selected([19, 9], 'vic'))
enddef

def g:Test_PythonFoldClosesFunction()
  if !Open() | return | endif
  # zc on a "def" line closes the function, not the enclosing class
  # (pyright has no foldingRange; the folds come from its symbols).
  h.WaitFor(() => exists('b:kzx_folds'), 'symbol folds')
  normal! zR
  cursor(18, 5)
  normal! zc
  assert_equal([18, 21], [foldclosed(18), foldclosedend(18)])
  # Known difference: tree-sitter also folds the import block; symbols don't.
enddef

def g:Test_PythonFormatOnSaveUsesBlack()
  if !Open() || !executable('black') | return | endif
  var path = $'{$VIM_TEST_TMP}/python/b.py'
  mkdir(fnamemodify(path, ':h'), 'p')
  writefile(['def f( a ):', "    return {'a':a}"], path)
  execute $'edit {path}'
  h.WaitForServers(['pyright'])
  silent write
  assert_equal(['def f(a):', '    return {"a": a}'], readfile(path))
enddef

def g:Test_PythonPyrightCommands()
  if !Open() | return | endif
  # lsp/pyright.lua defines these in on_attach.
  assert_equal(2, exists(':LspPyrightOrganizeImports'))
  assert_equal(2, exists(':LspPyrightSetPythonPath'))
enddef
