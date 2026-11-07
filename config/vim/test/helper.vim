vim9script
# Test helpers for the Vim config; sourced by every test_*.vim through run.sh.
# A test file defines global "Test_*" functions; RunTests() runs them in order
# and writes one result line per test to $VIM_TEST_OUT.

export const root = expand('<sfile>:p:h')

# Path of a fixture file or directory.
export def Fixture(path: string): string
  return $'{root}/fixtures/{path}'
enddef

# Wait until Cond() is true, failing the test after "timeout" ms.
export def WaitFor(Cond: func(): bool, msg: string, timeout = 10000): bool
  var start = reltime()
  while reltime(start)->reltimefloat() * 1000 < timeout
    if Cond()
      return true
    endif
    sleep 50m
  endwhile
  v:errors->add($'Timed out after {timeout}ms waiting for: {msg}')
  return false
enddef

# Names of the language servers attached to the current buffer.
export def Servers(): list<string>
  return lsp#buffer#CurbufGetServers()->copy()->map((_, s) => s.name)
enddef

# Wait until all "names" are attached to the current buffer and ready.
export def WaitForServers(names: list<string>, timeout = 60000): bool
  return WaitFor(() => names->copy()->filter((_, n) => lsp#buffer#CurbufGetServers()
    ->copy()->filter((_, s) => s.name == n && s.ready)->empty())->empty(),
    $'servers {names} on {bufname()}', timeout)
enddef

# Wait for the diagnostics of the current buffer to satisfy Cond(diags).
export def WaitForDiags(Cond: func(list<dict<any>>): bool, timeout = 60000): bool
  return WaitFor(() => Cond(lsp#diag#GetDiagsForBuf()), $'diagnostics on {bufname()}', timeout)
enddef

# Wait for the symbols used by the textobjects/motions to be available.
export def WaitForSymbols(timeout = 60000): bool
  return WaitFor(() => !lsp#buffer#CurbufGetServer('documentSymbol')->empty()
    && !lsp#buffer#CurbufGetServer('documentSymbol')
      .rpc('textDocument/documentSymbol', {textDocument: {uri: lsp#util#LspBufnrToUri(bufnr())}}, {timeout: 5000})
      ->get('result', [])->empty(), $'document symbols on {bufname()}', timeout)
enddef

# Run normal-mode keys with mappings, as if typed.
export def Feed(keys: string)
  feedkeys(keys, 'xt')
enddef

# Cursor position as [lnum, col].
export def Pos(): list<number>
  return getcurpos()[1 : 2]
enddef

# Copy a fixture to a scratch dir so the test can modify it.
export def Scratch(path: string): string
  var dest = $'{$VIM_TEST_TMP}/{path}'
  mkdir(fnamemodify(dest, ':h'), 'p')
  writefile(readfile(Fixture(path), 'b'), dest, 'b')
  return dest
enddef

# Errors (E123:) Vim printed so far, e.g. while sourcing the config.
export def ErrorMessages(): list<string>
  return execute('messages')->split("\n")->filter((_, l) => l =~ '\<E\d\+:')
enddef

def Result(name: string, errors: list<string>, ms: float)
  writefile([json_encode({name: name, errors: errors, ms: float2nr(ms)})], $VIM_TEST_OUT, 'a')
enddef

export def RunTests()
  # Report errors from loading the config before running anything.
  Result('startup', ErrorMessages(), 0.0)
  var only = $VIM_TEST_FILTER
  for f in getcompletion('Test_', 'function')
    var name = f->substitute('()\=$', '', '')
    if !only->empty() && name !~ only
      continue
    endif
    v:errors = []
    var start = reltime()
    try
      call(name, [])
    catch
      v:errors->add($'{v:exception} @ {v:throwpoint}')
    endtry
    Result(name, v:errors, reltime(start)->reltimefloat() * 1000)
    # Reset state a test may leave behind for the next one.
    popup_clear(1)
    silent! only!
    silent! :%bwipeout!
    setqflist([], 'f')
  endfor
  qa!
enddef

# The config is loaded; give language servers (which inherit the environment)
# the user's real config dir, so tools like mise work and nothing writes into
# the repository's config dir.
$XDG_CONFIG_HOME = $VIM_TEST_XDG_CONFIG_HOME

# Keep failures from blocking on "Press ENTER" prompts.
# A big screen so popups (completion menu) fit, and a tall cmdline so long
# messages do not prompt.
set nomore lines=60 columns=200 cmdheight=10 shortmess+=F
autocmd VimEnter * ++once timer_start(0, (_) => RunTests())
