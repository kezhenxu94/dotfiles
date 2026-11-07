vim9script
# lua_ls (+ stylua): compared with Neovim (tree-sitter + vim.lsp + lazydev)
# on fixtures/lua. The expected values are what Neovim does.
import './helper.vim' as h

def Open(): bool
  if !executable('lua-language-server')
    return false
  endif
  execute $'edit {h.Fixture('lua/a.lua')}'
  return h.WaitForServers(['lua_ls'])
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

def Messages(): list<string>
  return lsp#diag#GetDiagsForBuf()->mapnew((_, d) => $'{d.range.start.line + 1}: {d.message}')
enddef

def g:Test_LuaOnlyLuaLsAttaches()
  if !Open() | return | endif
  assert_equal(['lua_ls'], h.Servers())
enddef

def g:Test_LuaDiagnostics()
  if !Open() | return | endif
  h.WaitForDiags((d) => !d->empty())
  assert_true(Messages()->index('20: Undefined global `undefined_global`.') >= 0, string(Messages()))
  assert_equal([20, 17], Mapped([1, 1], ']d'))
enddef

# lazydev gives lua_ls the Neovim runtime (and LuaJIT) in every workspace.
def g:Test_LuaKnowsNeovimRuntime()
  if !Open() | return | endif
  h.WaitForDiags((d) => !d->empty())
  assert_equal(['20: Undefined global `undefined_global`.'], Messages())
enddef

def g:Test_LuaInlayHints()
  if !Open() | return | endif
  var Hints = () => prop_list(1, {end_lnum: -1, types: ['LspInlayHintsParam']})
    ->mapnew((_, p) => [p.lnum, p.col, p.text])
  # yegappan/lsp asks for the hints on CursorHold (throttled by a timer).
  doautocmd <nomodeline> CursorHold
  h.WaitFor(() => !Hints()->empty(), 'inlay hints')
  assert_equal([[11, 18, 'a: '], [20, 13, 'x: ']], Hints())
  h.Feed(' tih')
  assert_equal([], Hints())
  h.Feed(' tih')
  h.WaitFor(() => !Hints()->empty(), 'inlay hints back')
enddef

def g:Test_LuaFunctionMotions()
  if !Open() | return | endif
  h.WaitForSymbols()
  assert_equal([4, 1], Mapped([1, 1], ']m'))
  assert_equal([7, 3], Mapped([1, 1], ']M'))
  assert_equal([14, 3], Mapped([9, 1], ']M'))
  # A function starts at "local function" / "function", not at the name it
  # is assigned to.
  assert_equal([9, 1], Mapped([5, 5], ']m'))
  assert_equal([16, 8], Mapped([11, 5], ']m'))
  assert_equal([16, 8], Mapped([17, 3], '[m'))
enddef

def g:Test_LuaAroundFunction()
  if !Open() | return | endif
  h.WaitForSymbols()
  assert_equal([[4, 1], [7, 3], 'v'], Selected([5, 5], 'vam'))
  assert_equal([[9, 1], [14, 3], 'v'], Selected([11, 5], 'vam'))
  assert_equal([[16, 8], [18, 3], 'v'], Selected([17, 3], 'vam'))
enddef

def g:Test_LuaInnerFunctionIsTheBody()
  if !Open() | return | endif
  h.WaitForSymbols()
  # Not the inside of a table constructor, and not the "end" line.
  assert_equal([[5, 3], [6, 16], 'v'], Selected([5, 5], 'vim'))
  assert_equal([[10, 3], [13, 10], 'v'], Selected([11, 5], 'vim'))
  assert_equal([[17, 3], [17, 11], 'v'], Selected([17, 3], 'vim'))
enddef

def g:Test_LuaFoldIncludesEnd()
  if !Open() | return | endif
  h.WaitFor(() => exists('b:kzx_folds'), 'folds')
  normal! zR
  cursor(9, 1)
  normal! zc
  assert_equal([9, 14], [foldclosed(9), foldclosedend(9)])
  normal! zR
  assert_equal([1, 2, 1], [foldlevel(7), foldlevel(12), foldlevel(14)])
enddef

def g:Test_LuaFormatOnSaveUsesStylua()
  if !Open() || !executable('stylua') | return | endif
  var path = $'{$VIM_TEST_TMP}/lua/b.lua'
  mkdir(fnamemodify(path, ':h'), 'p')
  writefile(['{}'], $'{$VIM_TEST_TMP}/lua/.luarc.json')
  writefile(['local t = {1,2}', 'function  f( a )', 'return a end'], path)
  execute $'edit {path}'
  h.WaitForServers(['lua_ls'])
  silent write
  assert_equal(['local t = { 1, 2 }', 'function f(a)', "\treturn a", 'end'], readfile(path))
enddef
