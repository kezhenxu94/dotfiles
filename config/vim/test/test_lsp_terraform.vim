vim9script
# terraform-ls on a small module (no clone has .tf files), compared with
# Neovim on the same fixture. Formatting needs the terraform CLI, which
# terraform-ls shells out to.
import './helper.vim' as h

const main = 'terraform/main.tf'

# A scratch copy of the module, with a .terraform/ root marker (the fixture
# itself is rooted at the dotfiles repository).
# A fresh copy of the module per call: terraform-ls keeps the text of an
# edited buffer after it is wiped, so tests must not share a file.
var copies = 0
def Scratch(): string
  copies += 1
  var dir = $'{$VIM_TEST_TMP}/terraform{copies}'
  mkdir($'{dir}/.terraform', 'p')
  for f in ['main.tf', 'terraform.tfvars']
    writefile(readfile(h.Fixture($'terraform/{f}')), $'{dir}/{f}')
  endfor
  return $'{dir}/main.tf'
enddef

# Open "path" and wait until terraform-ls has loaded the module: a hover
# result on "var.greeting" (line 7) means it has.
def Open(path = h.Fixture(main)): bool
  if !executable('terraform-ls')
    return false
  endif
  execute $'edit {path}'
  if !h.WaitForServers(['terraformls'])
    return false
  endif
  var server = lsp#buffer#CurbufGetServer('hover')
  return h.WaitFor(() => type(server.rpc('textDocument/hover', {
    textDocument: {uri: lsp#util#LspBufnrToUri(bufnr())},
    position: {line: 6, character: 14}})->get('result', v:null)) == v:t_dict,
    'terraform-ls loaded the module', 30000)
enddef

def PopupText(): string
  return popup_list()->filter((_, id) => popup_getpos(id).visible)
    ->mapnew((_, id) => getbufline(winbufnr(id), 1, '$')->join("\n"))->join("\n")
enddef

# Type "keys" in Insert mode below "lnum", then (after ending any completion)
# "trigger", one key per second (terraform-ls answers "var." with nothing; the
# completion is refreshed on the next key); once completion offers "want",
# type "finish" (which should end Insert mode) and return the completion words.
def Complete(lnum: number, keys: string, trigger: list<string>, want: string,
    finish = "\<C-e>\<Esc>", timeout = 20000): list<string>
  var words: list<string>
  var start = reltime()
  var typed = 0
  timer_start(50, (t) => {
    var elapsed = reltime(start)->reltimefloat() * 1000
    if typed < len(trigger) && elapsed > 1000 * (typed + 1)
      feedkeys((typed == 0 && complete_info(['mode']).mode != '' ? "\<C-e>" : '') .. trigger[typed], 't')
      typed += 1
      return
    endif
    # The menu itself may not fit on the test screen, so ask complete_info().
    var info = complete_info(['mode', 'items'])
    var items = info.mode == 'omni' ? info.items->mapnew((_, i) => i.word) : []
    if items->index(want) >= 0 || elapsed > timeout
      words = items
      timer_stop(t)
      feedkeys(items->index(want) >= 0 ? finish : "\<C-e>\<Esc>", 't')
    endif
  }, {repeat: -1})
  cursor(lnum, 1)
  feedkeys($"o{keys}", 'xt!')
  return words
enddef

def g:Test_TerraformServers()
  if !Open() | return | endif
  assert_equal('terraform', &filetype)
  assert_equal(['terraformls'], h.Servers())
  execute $'edit {h.Fixture('terraform/terraform.tfvars')}'
  h.WaitForServers(['terraformls'])
  assert_equal('terraform-vars', &filetype)
  assert_equal(['terraformls'], h.Servers())
enddef

def g:Test_TerraformHover()
  if !Open() | return | endif
  cursor(7, 15)
  h.Feed('K')
  h.WaitFor(() => PopupText() =~ 'greeting', 'hover popup')
  assert_match('var\.greeting', PopupText())
  assert_match('string', PopupText())
  popup_clear()
enddef

def g:Test_TerraformDefinition()
  if !Open() | return | endif
  cursor(7, 15)
  h.Feed("\<C-]>")
  assert_equal([1, 1], h.Pos())
enddef

def g:Test_TerraformDiagnostics()
  if !Open(Scratch()) | return | endif
  setline(2, '  foo  = string')
  if !h.WaitForDiags((d) => !d->empty()) | return | endif
  var diags = lsp#diag#GetDiagsForBuf()
  assert_equal([[2, 1]], diags->mapnew((_, d) => [d.range.start.line + 1, d.severity]))
  assert_match('Unexpected attribute', diags[0].message)
enddef

def g:Test_TerraformCompletionOffersVariables()
  if !Open(Scratch()) | return | endif
  setline(7, '')
  assert_equal(['var.greeting'], Complete(6, 'value = var', ['.', 'g'], 'var.greeting'))
enddef

def g:Test_TerraformCompletionReplacesTypedPrefix()
  # The item's textEdit replaces "var.g" (Neovim inserts "var.greeting");
  # with the fuzzy matcher yegappan/lsp ignores textEdit and inserts the
  # label after "var.", giving "var.var.greeting".
  if !Open(Scratch()) | return | endif
  setline(7, '')
  Complete(6, 'value = var', ['.', 'g'], 'var.greeting', "\<C-n>\<CR>\<Esc>")
  assert_equal('  value = var.greeting', getline(7))
enddef
