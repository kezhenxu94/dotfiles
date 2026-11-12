vim9script
# jdtls on a tiny Maven project (test/fixtures/java). jdtls is slow to start,
# so every test shares the one server started by the first test.
import './helper.vim' as h

const files = ['pom.xml'] + ['Shapes', 'Broken', 'Point', 'Imports']
  ->mapnew((_, f) => $'src/main/java/demo/{f}.java')
const timeout = 180000
var started = true

# Copy the fixture project once and open "file" from it; the copy lives outside
# the dotfiles repo so its .git does not become the root.
def Open(file: string): bool
  if !executable('jdtls')
    return false
  endif
  if !filereadable($'{$VIM_TEST_TMP}/java/pom.xml')
    for f in files
      h.Scratch($'java/{f}')
    endfor
  endif
  execute $'edit {$VIM_TEST_TMP}/java/src/main/java/demo/{file}'
  if !started
    v:errors->add('jdtls did not start')
    return false
  endif
  started = h.WaitForServers(['jdtls'], timeout) && WaitForIndex()
  return started
enddef

# jdtls answers before it has imported the project; hovering the class name
# (line 5 of both files) only works once it has.
var indexed = false
def WaitForIndex(): bool
  if !indexed
    var params = {textDocument: {uri: lsp#util#LspBufnrToUri(bufnr())}, position: {line: 4, character: 14}}
    indexed = h.WaitFor(() => Server().rpc('textDocument/hover', params, {timeout: 5000})
      ->get('result', null_dict) != null, 'jdtls imported the project', timeout)
  endif
  return indexed
enddef

def Server(): dict<any>
  return lsp#buffer#CurbufGetServers()->copy()->filter((_, s) => s.name == 'jdtls')->get(0, {})
enddef

# Type "keys" and stay in Insert mode until the completion menu has items
# (or "wait" ms passed), then type "after" (which must leave Insert mode).
# Returns the words in the menu.
def Complete(keys: string, after: string, wait = 30000): list<string>
  # A dict, so that the timer callback and this function share it.
  var state: dict<any> = {words: [], done: false, start: reltime()}
  def Poll(_: number)
    var info = complete_info(['mode', 'items'])
    if info.mode == 'omni' && !info.items->empty()
      state.words = info.items->mapnew((_, i) => i.word)
    endif
    if !state.words->empty() || state.start->reltime()->reltimefloat() * 1000 > wait
      feedkeys(after, 't')
      state.done = true
    else
      timer_start(50, Poll)
    endif
  enddef
  timer_start(50, Poll)
  feedkeys(keys, 'xt!')
  # Keys fed by the trigger-character handler can end the wait early.
  h.WaitFor((): bool => state.done, 'completion polling', wait + 1000)
  feedkeys('', 'x')
  return state.words
enddef

def Mapped(start: list<number>, keys: string): list<number>
  cursor(start)
  h.Feed(keys)
  return h.Pos()
enddef

# [start line, start col, end line, end col] yanked by "y{textobj}".
def Yanked(start: list<number>, textobj: string): list<number>
  cursor(start)
  setreg('z', '')
  h.Feed($'"zy{textobj}')
  if getreg('z')->empty()
    return []
  endif
  return getpos("'[")[1 : 2] + getpos("']")[1 : 2]
enddef

def g:Test_Java_RootAndWorkspace()
  if !Open('Shapes.java')
    return
  endif
  var server = Server()
  assert_equal([$'{$VIM_TEST_TMP}/java/'], server.workspaceFolders, 'root is the pom.xml directory')
  # Like nvim: one workspace data dir per root, named after the root (each
  # root's instance is started in that root).
  assert_equal(['java'], readdir($'{$XDG_CACHE_HOME}/vim/jdtls/workspace'), 'workspace data dir keyed on the root')
enddef

def g:Test_Java_Diagnostics()
  if !Open('Broken.java')
    return
  endif
  # jdtls (in both editors) does not report the unused import.
  h.WaitForDiags((d) => !d->empty(), timeout)
  var diags = lsp#diag#GetDiagsForBuf()->mapnew((_, d) => [d.range.start.line + 1, d.severity])
  assert_equal([[7, 1]], diags, 'type error on line 7')
  cursor(1, 1)
  h.Feed(']d')
  assert_equal(7, line('.'), ']d')
  cursor(9, 1)
  h.Feed('[e')
  assert_equal(7, line('.'), '[e')
enddef

def g:Test_Java_OrganizeImports()
  if !Open('Broken.java')
    return
  endif
  h.WaitForDiags((d) => !d->empty(), timeout)
  h.Feed(' co')
  h.WaitFor(() => getline(3) !~ 'import', 'unused import removed')
  assert_equal(-1, getline(1, '$')->index('import java.util.Map;'))
enddef

# Vim does not watch pom.xml, so jdtls only sees its changes on :JdtUpdateConfig.
def g:Test_Java_UpdateConfig()
  if !Open('Shapes.java')
    return
  endif
  var pom = $'{$VIM_TEST_TMP}/java/pom.xml'
  var rec = $'{$VIM_TEST_TMP}/java/src/main/java/demo/Rec.java'
  var orig = readfile(pom)
  writefile(['package demo;', 'public record Rec(int x) {}'], rec)
  execute $'edit {rec}'
  h.WaitForServers(['jdtls'], timeout)
  try
    # Records need Java 16+.
    writefile(orig->mapnew((_, l) => l->substitute('>17<', '>11<', '')), pom)
    execute 'JdtUpdateConfig'
    h.WaitForDiags((d) => !d->empty(), timeout)
  finally
    # Restore the shared server's config without waiting: jdtls does not
    # revalidate open files on an update sent while it still builds.
    writefile(orig, pom)
    execute 'JdtUpdateConfig'
    bwipe!
    delete(rec)
  endtry
enddef

def g:Test_Java_CompletionAddsImport()
  if !Open('Broken.java')
    return
  endif
  # Complete a class name and accept the first item.
  cursor(5, 1)
  assert_notequal([], Complete("oprivate ArrayLis\<C-x>\<C-o>", "\<C-n>\<C-y>\<Esc>"), 'completion menu')
  h.WaitFor(() => getline(1, '$')->index('import java.util.ArrayList;') >= 0, 'import inserted')
  assert_match('ArrayList\s*$', getline(7))
enddef

def g:Test_Java_CompletionOnDot()
  if !Open('Shapes.java')
    return
  endif
  # The trigger character "." opens the menu.
  cursor(37, 1)
  var words = Complete('oshapes.', "\<C-e>\<Esc>")
  assert_true(words->copy()->filter((_, w) => w =~ '\<area\>')->len() > 0, $'area() offered: {words}')
enddef

def g:Test_Java_Hover()
  if !Open('Shapes.java')
    return
  endif
  cursor(37, 35)  # area
  h.Feed('K')
  h.WaitFor(() => !popup_list()->empty(), 'hover popup')
  var text = popup_list()->mapnew((_, p) => winbufnr(p)->getbufline(1, '$')->join("\n"))->join("\n")
  assert_match('int demo.Shapes.area()', text)
  popup_clear()
enddef

def g:Test_Java_DefinitionInProject()
  if !Open('Shapes.java')
    return
  endif
  cursor(37, 35)  # area
  h.Feed("\<C-]>")
  assert_equal([15, 16], h.Pos())
enddef

def g:Test_Java_DefinitionIntoJdk()
  if !Open('Shapes.java')
    return
  endif
  var shapes = bufnr()
  # nvim-jdtls opens jdt:// URIs (java/classFileContents) of JDK classes.
  cursor(19, 12)  # Supplier
  h.Feed("\<C-]>")
  h.WaitFor(() => getline(1, '$')->join("\n") =~ 'interface Supplier', 'Supplier source opened')
  assert_match('^jdt://contents/java.base/java.util.function/Supplier\.\(class\|java\)?', bufname())
  assert_equal(['java', 'nofile', false], [&filetype, &buftype, &modifiable])
  assert_match('public interface Supplier<T>', getline('.'))
  # The jdtls instance of the project serves the class too: from it to
  # another JDK class, and back with the tag stack.
  assert_true(h.WaitForServers(['jdtls'], 30000))
  assert_equal(Server().id, JdtlsOf(shapes).id, 'same jdtls instance')
  search('^@FunctionalInterface')
  normal! l
  h.Feed("\<C-]>")
  h.WaitFor(() => bufname() =~ 'java.lang/FunctionalInterface', 'FunctionalInterface source opened')
  assert_match('public @interface FunctionalInterface', getline('.'))
  h.Feed("\<C-t>")
  assert_match('Supplier.class', bufname())
  h.Feed("\<C-t>")
  assert_equal([shapes, 19, 12], [bufnr(), line('.'), col('.')])
enddef

def JdtlsOf(bnr: number): dict<any>
  return lsp#buffer#BufLspServersGet(bnr)->copy()->filter((_, s) => s.name == 'jdtls')->get(0, {})
enddef

# grr fills the quickfix list from the same locations; jdtls takes longer
# than yegappan/lsp's 2s request timeout to search the JDK for references, so
# show a jdt:// location directly.
def g:Test_Java_JdtLocationInQuickfix()
  if !Open('Shapes.java')
    return
  endif
  var params = {textDocument: {uri: lsp#util#LspBufnrToUri(bufnr())}, position: {line: 18, character: 11}}
  var locs = Server().rpc('textDocument/definition', params, {timeout: 30000})->get('result', [])
  assert_equal(1, len(locs))
  lsp#symbol#ShowLocations(Server(), locs, false, 'References')
  var qf = getqflist()
  assert_equal([1, 'public interface Supplier<T> {'], [len(qf), qf[0].text])
  cclose
  cfirst
  assert_equal(['public interface Supplier<T> {', 'java'], [getline('.'), &filetype])
enddef

def g:Test_Java_Rename()
  if !Open('Shapes.java')
    return
  endif
  cursor(15, 16)  # area
  h.Feed("grn\<C-u>surface\<CR>")
  h.WaitFor(() => getline(15) =~ 'surface()', 'renamed')
  assert_match('return surface();', getline(21))
  assert_match('shapes.surface()', getline(37))
enddef

def g:Test_Java_InlayHints()
  if !Open('Shapes.java')
    return
  endif
  # jdtls names literal arguments: new Shapes(size: 2). Hints of a reopened
  # buffer show up on CursorHold.
  doautocmd CursorHold
  h.WaitFor(() => prop_list(36)->filter((_, p) => p.type =~ 'Inlay')->len() > 0, 'inlay hint on line 36', 30000)
enddef

def g:Test_Java_Folds()
  if !Open('Shapes.java')
    return
  endif
  h.WaitFor(() => &foldmethod == 'expr', 'folds from the server', 30000)
  # Same as nvim's tree-sitter folds, except that jdtls also folds javadoc
  # and interface bodies.
  assert_equal([0, 1, 2, 2, 2, 1, 2, 3, 3, 3, 2, 3],
    [4, 5, 8, 9, 10, 11, 19, 20, 21, 22, 23, 26]->mapnew((_, l) => foldlevel(l)))
enddef

def g:Test_Java_SemanticTokens()
  if !Open('Shapes.java')
    return
  endif
  h.WaitFor(() => prop_list(37)->filter((_, p) => p.type =~ 'LspSemantic')->len() > 0, 'semantic tokens', 30000)
enddef

# Expected positions are the ones nvim's tree-sitter textobjects give.
def g:Test_Java_FunctionMotions()
  if !Open('Shapes.java') || !h.WaitForSymbols(timeout)
    return
  endif
  assert_equal([8, 5], Mapped([1, 1], ']m'), ']m to the constructor')
  assert_equal([15, 5], Mapped([10, 5], ']m'), ']m skips the javadoc')
  assert_equal([31, 13], Mapped([27, 13], ']m'), ']m to the interface method')
  assert_equal([35, 5], Mapped([31, 13], ']m'), ']m out of the inner class')
  assert_equal([8, 5], Mapped([15, 5], '[m'))
  assert_equal([26, 9], Mapped([31, 13], '[m'))
  assert_equal([17, 5], Mapped([15, 5], ']M'))
  assert_equal([31, 33], Mapped([36, 9], '[M'))
  assert_equal([26, 9], Mapped([15, 5], ']m;'), '; repeats ]m')
  assert_equal([19, 5], Mapped([26, 9], ','), ', goes back')
enddef

def g:Test_Java_ClassMotions()
  if !Open('Shapes.java') || !h.WaitForSymbols(timeout)
    return
  endif
  assert_equal([5, 1], Mapped([1, 1], ']c'))
  assert_equal([25, 5], Mapped([5, 1], ']c'), ']c to the nested class')
  # Deliberately unlike nvim (whose Java @class.outer is class_declaration
  # only): interfaces and enums count as classes too.
  assert_equal([30, 9], Mapped([27, 13], ']c'), ']c stops at the inner interface')
  assert_equal([30, 9], Mapped([36, 9], '[c'))
  assert_equal([5, 1], Mapped([21, 13], '[c'), '[c from a lambda')
enddef

def g:Test_Java_TextObjects()
  if !Open('Shapes.java') || !h.WaitForSymbols(timeout)
    return
  endif
  assert_equal([15, 5, 17, 5], Yanked([15, 5], 'am'), 'am excludes the javadoc')
  assert_equal([19, 5, 23, 5], Yanked([21, 13], 'am'), 'am from inside a lambda')
  assert_equal([8, 5, 10, 5], Yanked([1, 1], 'am'), 'am looks ahead')
  assert_equal([31, 13, 31, 33], Yanked([31, 13], 'am'), 'am on an interface method')
  assert_equal([16, 9, 16, 27], Yanked([15, 5], 'im'))
  assert_equal([20, 9, 22, 10], Yanked([21, 13], 'im'))
  assert_equal([25, 5, 33, 5], Yanked([27, 13], 'ac'), 'ac on the nested class')
  assert_equal([5, 1, 39, 1], Yanked([36, 9], 'ac'))
  # nvim's ic (the class_body node) includes the braces, [25, 24, 33, 5];
  # Vim's stays inside them, which is less surprising, so allow both.
  var ic = Yanked([27, 13], 'ic')
  assert_true(ic->len() == 4 && ic[0] >= 25 && ic[0] <= 26 && ic[2] >= 32 && ic[2] <= 33,
    $'ic of the nested class: {ic}')
enddef

# Answers to the prompts of the jdtls commands: they prompt from a timer, so
# leave the keys in the typeahead for them.
def Answer(keys: string)
  feedkeys(keys, 'n')
enddef

def Lines(): list<string>
  return getline(1, '$')
enddef

def g:Test_Java_OrganizeImportsChooses()
  if !Open('Imports.java')
    return
  endif
  h.WaitForDiags((d) => !d->empty(), timeout)
  # Like nvim: "Choose type List to import" (com.sun..., java.util, java.awt).
  h.Feed(' co')
  Answer("2\<CR>")
  h.WaitFor(() => Lines()->index('import java.util.List;') >= 0, 'java.util.List imported', 30000)
  assert_equal(['package demo;', '', 'import java.util.List;', '', 'public class Imports {'], getline(1, 5))
enddef

# The generated code is the same as with nvim-jdtls (tabs are jdtls' default).
def g:Test_Java_GenerateConstructors()
  if !Open('Point.java')
    return
  endif
  cursor(3, 1)
  LspCodeAction /Generate Constructors
  Answer("1-2\<CR>\<CR>")
  h.WaitFor(() => Lines()->len() > 6, 'constructor generated', 30000)
  assert_equal(['    private int y;', "\tpublic Point(int x, int y) {", "\t\tthis.x = x;", "\t\tthis.y = y;", "\t}", '}'],
    getline(5, '$'))
enddef

def g:Test_Java_OverrideMethods()
  if !Open('Point.java')
    return
  endif
  cursor(3, 1)
  LspCodeAction /Override
  # 1. clone() 2. equals() 3. finalize() 4. hashCode() 5. toString()
  Answer("5\<CR>\<CR>")
  h.WaitFor(() => Lines()->len() > 6, 'method overridden', 30000)
  assert_equal(["\t@Override", "\tpublic String toString() {", "\t\treturn super.toString();", "\t}", '}'],
    getline(6, '$'))
enddef

def g:Test_Java_GenerateToString()
  if !Open('Point.java')
    return
  endif
  cursor(3, 1)
  LspCodeAction /Generate toString
  Answer("1\<CR>\<CR>")
  h.WaitFor(() => Lines()->len() > 6, 'toString() generated', 30000)
  assert_equal("\t\treturn \"Point [x=\" + x + \"]\";", getline(8))
enddef
