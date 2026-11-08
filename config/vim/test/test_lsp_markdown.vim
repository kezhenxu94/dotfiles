vim9script
# markdown-oxide (plus tailwindcss, which Neovim also attaches to markdown in
# a git repository): compared with Neovim on fixtures/markdown.
import './helper.vim' as h

def Dir(): string
  return $'{$VIM_TEST_TMP}/markdown'
enddef

# The scratch copy is outside any git repository: .moxide.toml is the root.
def Open(file = 'notes.md'): bool
  if !executable('markdown-oxide')
    return false
  endif
  for f in ['.moxide.toml', 'notes.md', 'other.md']
    h.Scratch($'markdown/{f}')
  endfor
  execute $'edit {Dir()}/{file}'
  return h.WaitForServers(['markdown_oxide'])
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

def g:Test_MarkdownServers()
  if !Open() | return | endif
  # tailwindcss needs a project (workspace_required): none here.
  assert_equal(['markdown_oxide'], h.Servers())
  if !executable('tailwindcss-language-server') | return | endif
  # Inside a git repository it attaches too, as in Neovim.
  mkdir($'{Dir()}/.git', 'p')
  defer delete($'{Dir()}/.git', 'rf')
  execute $'edit {Dir()}/other.md'
  h.WaitForServers(['markdown_oxide', 'tailwindcss'])
  assert_equal(['markdown_oxide', 'tailwindcss'], h.Servers()->sort())
enddef

def g:Test_MarkdownUnresolvedReference()
  if !Open() | return | endif
  h.WaitForDiags((d) => !d->empty())
  assert_equal([[3, 27, 3, 'Unresolved Reference']], lsp#diag#GetDiagsForBuf()
    ->mapnew((_, d) => [d.range.start.line + 1, d.range.start.character + 1, d.severity, d.message]))
  assert_equal([3, 27], Mapped([1, 1], ']d'))
enddef

def g:Test_MarkdownCompletionOnBracket()
  if !Open() | return | endif
  var words: list<string>
  var start = reltime()
  timer_start(50, (t) => {
    words = complete_info(['items']).items->mapnew((_, i) => i.abbr)
    if !words->empty() || reltime(start)->reltimefloat() > 20
      timer_stop(t)
      feedkeys("\<Esc>", 't')
    endif
  }, {repeat: -1})
  cursor(11, 1)
  feedkeys('o[[', 'xt!')
  assert_true(words->index('notes#Tasks') >= 0, string(words))
enddef

def g:Test_MarkdownHoverAndDefinition()
  if !Open() | return | endif
  cursor(3, 7)
  h.Feed('K')
  h.WaitFor(() => !popup_list()->empty(), 'hover popup')
  assert_match('File Preview', popup_list()
    ->mapnew((_, w) => getbufline(winbufnr(w), 1, '$')->join("\n"))->join("\n"))
  popup_clear()
  cursor(3, 7)
  h.Feed("\<C-]>")
  assert_equal('other.md', expand('%:t'))
  assert_equal([1, 1], h.Pos())
enddef

def g:Test_MarkdownDailyNoteCommands()
  if !Open() | return | endif
  for [cmd, offset] in [['LspToday', 0], ['LspTomorrow', 1], ['LspYesterday', -1]]
    var note = strftime('%Y-%m-%d', localtime() + offset * 86400) .. '.md'
    execute cmd
    h.WaitFor(() => expand('%:t') == note, $':{cmd} opens {note}')
    assert_equal(Dir(), expand('%:p:h'))
    # The commands exist in every markdown buffer, including the new note.
    assert_equal(2, exists($':{cmd}'))
  endfor
enddef

def g:Test_MarkdownFolds()
  if !Open() | return | endif
  assert_equal([1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3], range(1, line('$'))->mapnew((_, l) => foldlevel(l)))
enddef

def g:Test_MarkdownHeadingMotions()
  if !Open() | return | endif
  h.WaitForSymbols()
  assert_equal([[5, 1], [9, 1]], Moves([1, 1], ']c', 2))
  assert_equal([[9, 1], [5, 1]], Moves([11, 1], '[c', 2))
  assert_equal([5, 1], Mapped([1, 1], ']c'))
  assert_equal([9, 1], Mapped([5, 1], ';'))
  assert_equal([5, 1], Mapped([9, 1], ','))
enddef

# @class.outer is the heading line, @class.inner its text.
def g:Test_MarkdownHeadingTextobjects()
  if !Open() | return | endif
  h.WaitForSymbols()
  assert_equal([[9, 1], [9, 11]], Selected([6, 1], 'vac'))
  assert_equal([[9, 5], [9, 11]], Selected([9, 1], 'vic'))
enddef
