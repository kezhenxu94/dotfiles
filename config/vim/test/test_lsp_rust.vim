vim9script
# rust-analyzer: compared with Neovim (tree-sitter + vim.lsp) on
# fixtures/rust, a crate without dependencies. The expected values are what
# Neovim does. Conform has no Rust formatter, so saving formats through the
# language server.
import './helper.vim' as h

# rust-analyzer is usually a rustup proxy, which fails (or worse, falls back
# to other installations) when the toolchain lacks the component.
def Available(): bool
  if !executable('rust-analyzer') || !executable('cargo')
    return false
  endif
  if executable('rustup') && resolve(exepath('rust-analyzer'))->fnamemodify(':t') == 'rustup'
    system('rustup which rust-analyzer')
    return v:shell_error == 0
  endif
  return true
enddef

# Copy the crate to the scratch dir (cargo writes target/ next to it) and
# open src/lib.rs with rust-analyzer ready.
def Open(): bool
  if !Available()
    return false
  endif
  for f in ['Cargo.toml', 'src/lib.rs']
    h.Scratch($'rust/{f}')
  endfor
  execute $'edit {$VIM_TEST_TMP}/rust/src/lib.rs'
  return h.WaitForServers(['rust_analyzer'], 120000)
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

def g:Test_RustOnlyRustAnalyzerAttaches()
  if !Open() | return | endif
  assert_equal(['rust_analyzer'], h.Servers())
enddef

def g:Test_RustDiagnostics()
  if !Open() | return | endif
  h.WaitForDiags((d) => !d->empty(), 120000)
  var diags = lsp#diag#GetDiagsForBuf()
  assert_equal([10], diags->mapnew((_, d) => d.range.start.line)->uniq())
  assert_match('expected `\=i32', diags->mapnew((_, d) => d.message)->join("\n"))
  assert_equal([11, 22], Mapped([1, 1], ']e'))
enddef

def g:Test_RustLensSettings()
  if !Open() | return | endif
  # lsp/rust_analyzer.lua sends its settings both as initializationOptions
  # and as the "rust-analyzer" workspace configuration.
  var server = lsp#buffer#CurbufGetServer('documentSymbol')
  assert_equal(true, server->get('workspaceConfig', {})->get('rust-analyzer', {})->get('lens', {})->get('enable'))
  assert_equal(2, exists(':LspCargoReload'))
enddef

def g:Test_RustMotions()
  if !Open() | return | endif
  h.WaitForSymbols(120000)
  assert_equal([6, 5], Mapped([1, 1], ']m'))
  assert_equal([8, 5], Mapped([1, 1], ']M'))
  assert_equal([16, 1], Mapped([11, 9], ']m'))
  assert_equal([10, 5], Mapped([16, 1], '[m'))
  # impl blocks are classes too.
  assert_equal([5, 1], Mapped([1, 1], ']c'))
  assert_equal([5, 1], Mapped([11, 9], '[c'))
enddef

def g:Test_RustTextobjects()
  if !Open() | return | endif
  h.WaitForSymbols(120000)
  assert_equal([[6, 5], [8, 5], 'v'], Selected([7, 9], 'vam'))
  assert_equal([[7, 9], [7, 19], 'v'], Selected([7, 9], 'vim'))
  assert_equal([[11, 9], [12, 18], 'v'], Selected([11, 9], 'vim'))
  assert_equal([[16, 36], [16, 38], 'v'], Selected([16, 1], 'vim'))
  assert_equal([[1, 1], [3, 1], 'v'], Selected([2, 5], 'vac'))
  assert_equal([[2, 5], [2, 15], 'v'], Selected([2, 5], 'vic'))
  assert_equal([[5, 1], [14, 1], 'v'], Selected([11, 9], 'vac'))
  assert_equal([[6, 5], [13, 5], 'v'], Selected([11, 9], 'vic'))
enddef

def g:Test_RustFolds()
  if !Open() | return | endif
  h.WaitFor(() => exists('b:kzx_folds'), 'folds', 120000)
  assert_equal([1, 1, 1, 0, 1, 2, 2, 2, 1, 2, 2, 2, 2, 1, 0, 0],
    range(1, line('$'))->mapnew((_, l) => foldlevel(l)))
enddef

def g:Test_RustFormatOnSaveFallsBackToLsp()
  if !Open() | return | endif
  silent write
  assert_equal(['pub fn add(a: i32, b: i32) -> i32 {', '    a + b', '}'], readfile(expand('%'))[15 :])
enddef
