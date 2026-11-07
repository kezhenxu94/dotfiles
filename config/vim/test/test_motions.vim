vim9script
# Repeatable motions (;/,) and the builtin fallbacks used without a server.
import './helper.vim' as h

# Where the builtin "keys" (no mappings) move the cursor from "start".
def Builtin(start: list<number>, keys: string): list<number>
  cursor(start)
  execute $'normal! {keys}'
  return h.Pos()
enddef

def Mapped(start: list<number>, keys: string): list<number>
  cursor(start)
  h.Feed(keys)
  return h.Pos()
enddef

def g:Test_FunctionMotionsFallBackToBuiltin()
  execute $'edit {h.Fixture('motions/a.c')}'
  assert_equal([], h.Servers(), 'no language server for C')
  for keys in [']m', '[m', ']M', '[M', '2]m', ']]']
    for start in [[1, 1], [7, 5], [14, 1]]
      assert_equal(Builtin(start, keys), Mapped(start, keys), $'{keys} from {start}')
    endfor
  endfor
enddef

def g:Test_ClassMotionInDiffModeIsDiffJump()
  execute $'edit {h.Fixture('motions/text.txt')}'
  diffthis
  vnew
  setline(1, ['one two three four', 'CHANGED', 'eight nine ten'])
  diffthis
  wincmd p
  assert_equal([2, 1], Mapped([1, 1], ']c'))
  assert_equal([2, 1], Mapped([3, 1], '[c'))
  diffoff!
enddef

def g:Test_SemicolonCommaAlwaysForwardBackward()
  execute $'edit {h.Fixture('motions/text.txt')}'
  # Line 4: aXbXcXdXe
  # f: ; forward, , backward (builtin semantics).
  assert_equal([4, 2], Mapped([4, 1], 'fX'))
  assert_equal([4, 4], Mapped([4, 2], ';'))
  assert_equal([4, 2], Mapped([4, 4], ','))
  # F: ; still goes forward (repeat_last_move_next), , backward.
  assert_equal([4, 6], Mapped([4, 7], 'FX'))
  assert_equal([4, 8], Mapped([4, 6], ';'), '; after F goes forward')
  assert_equal([4, 6], Mapped([4, 8], ','))
  # Line 5: abcXabcXabcX; t/T behave the same.
  assert_equal([5, 3], Mapped([5, 1], 'tX'))
  assert_equal([5, 7], Mapped([5, 3], ';'))
  assert_equal([5, 5], Mapped([5, 7], ','), ', after t goes backward')
  assert_equal([5, 9], Mapped([5, 11], 'TX'))
  assert_equal([5, 11], Mapped([5, 9], ';'), '; after T goes forward')
  assert_equal([5, 9], Mapped([5, 11], ','))
enddef

def g:Test_CountsAndOperators()
  execute $'edit {h.Fixture('motions/text.txt')}'
  assert_equal([1, 13], Mapped([1, 1], '3fe'))
  cursor(1, 1)
  h.Feed('dfo')
  assert_equal(' three four', getline(1))
  h.Feed(';')
  assert_equal([1, 9], h.Pos(), '; after d{f} repeats the f')
  undo
enddef

def Git(dir: string, cmd: string)
  system($'git -C {shellescape(dir)} -c user.name=t -c user.email=t@t {cmd}')
enddef

def g:Test_HunkJumpsAreRepeatable()
  var dir = $'{$VIM_TEST_TMP}/repo'
  mkdir(dir, 'p')
  Git(dir, 'init -q')
  writefile(range(1, 20)->mapnew((_, n) => string(n)), $'{dir}/f.txt')
  Git(dir, 'add f.txt')
  Git(dir, 'commit -qm init')
  execute $'edit {dir}/f.txt'
  setline(3, 'x')
  setline(10, 'y')
  setline(17, 'z')
  GitGutter
  h.WaitFor(() => len(gitgutter#hunk#hunks(bufnr())) == 3, 'gitgutter hunks')
  assert_equal([3, 1], Mapped([1, 1], ']h'))
  assert_equal([10, 1], Mapped([3, 1], ';'))
  assert_equal([17, 1], Mapped([10, 1], ';'))
  assert_equal([10, 1], Mapped([17, 1], ','))
  assert_equal([3, 1], Mapped([10, 1], '[h'))
  assert_equal([10, 1], Mapped([3, 1], ';'), '; after [h goes forward')
  # A later f takes over ;/, again.
  assert_equal([10, 1], Mapped([10, 1], 'fy'))
enddef
