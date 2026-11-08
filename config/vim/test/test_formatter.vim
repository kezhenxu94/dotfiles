vim9script
# Format on save (port of the conform.nvim setup).
import './helper.vim' as h

# Write a scratch copy of fixture "name" and return the formatted lines.
def Saved(name: string): list<string>
  execute $'edit {h.Scratch('format/' .. name)}'
  silent write
  return readfile(expand('%'))
enddef

def Skip(...tools: list<string>): bool
  return tools->copy()->filter((_, t) => !executable(t))->len() > 0
enddef

def g:Test_Gofmt()
  if Skip('gofmt') | return | endif
  assert_equal(['package main', '', 'func f() {', "\tx := 1", "\t_ = x", '}'], Saved('a.go'))
enddef

def g:Test_JqUsesShiftwidth()
  if Skip('jq') | return | endif
  assert_equal(['{', '  "a": 1,', '  "b": [', '    1,', '    2', '  ]', '}'], Saved('a.json'))
enddef

def g:Test_ShfmtIndentsWithShiftwidth()
  if Skip('shfmt') | return | endif
  assert_equal(['if true; then', '  echo hi', 'fi'], Saved('a.sh'))
enddef

def g:Test_Yq()
  if Skip('yq') | return | endif
  assert_equal(['a: 1', 'b:', '  - x'], Saved('a.yaml'))
enddef

def g:Test_Black()
  if Skip('black') | return | endif
  assert_equal(['x = {"a": 1}', '', '', 'def f(a):', '    return a'], Saved('a.py'))
enddef

def g:Test_JavascriptStopsAfterFirst()
  if Skip('prettierd') | return | endif
  assert_equal(['const a = { b: 1 };'], Saved('a.js'))
enddef

def g:Test_FailingFormatterKeepsBuffer()
  if Skip('eslint_d') | return | endif
  # eslint_d fails outside an eslint project; like conform, nothing changes.
  assert_equal(['export const a = {b:1}'], Saved('a.ts'))
enddef

def g:Test_CompoundFiletypeUsesParts()
  if Skip('yq') | return | endif
  var path = $'{$VIM_TEST_TMP}/.github/workflows/a.yaml'
  mkdir(fnamemodify(path, ':h'), 'p')
  writefile(readfile(h.Fixture('format/a.yaml')), path)
  execute $'edit {path}'
  assert_equal('yaml.github-actions', &filetype)
  silent write
  assert_equal(['a: 1', 'b:', '  - x'], readfile(path))
enddef

def g:Test_ToggleBufferAutoformat()
  if Skip('gofmt') | return | endif
  execute $'edit {h.Scratch('format/a.go')}'
  h.Feed(' tff')
  silent write
  assert_equal(readfile(h.Fixture('format/a.go')), readfile(expand('%')))
  h.Feed(' tff')
  silent write
  assert_equal('func f() {', readfile(expand('%'))[2])
enddef

def g:Test_GlobalDisable()
  if Skip('gofmt') | return | endif
  g:disable_autoformat = true
  try
    assert_equal(readfile(h.Fixture('format/a.go')), Saved('a.go'))
  finally
    unlet g:disable_autoformat
  endtry
enddef

def g:Test_ProjectOverrideIgnoresStderr()
  if Skip('google-java-format') | return | endif
  # Like formatters_by_ft of conform in a project's .nvim.lua; the JVM notes
  # "Picked up JDK_JAVA_OPTIONS" on stderr, which must not end in the buffer.
  g:formatters_by_ft = {java: ['google-java-format']}
  setenv('JDK_JAVA_OPTIONS', '-Xss2m')
  try
    assert_equal(['class A {', '  void f() {', '    int x = 1;', '  }', '}'], Saved('A.java'))
  finally
    unlet g:formatters_by_ft
    setenv('JDK_JAVA_OPTIONS', null)
  endtry
enddef
