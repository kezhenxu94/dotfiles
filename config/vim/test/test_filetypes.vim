vim9script
# Filetypes match Neovim's (the LSP servers key on them).
import './helper.vim' as h

def Ft(path: string): string
  execute $'edit {h.Fixture('filetypes/' .. path)}'
  return &filetype
enddef

def g:Test_Filetypes()
  # Neovim: "yaml", plus gh_actions_ls through its root_dir check.
  assert_equal('yaml.github-actions', Ft('.github/workflows/ci.yml'))
  assert_equal('yaml', Ft('compose.yaml'))
  assert_equal('yaml', Ft('docker-compose.yml'))
  assert_equal('hcl', Ft('docker-bake.hcl'))
  assert_equal('markdown', Ft('doc.mdx'))
  assert_equal('yaml', Ft('chart/Chart.yaml'))
  assert_equal('helm', Ft('chart/templates/a.yaml'))
  assert_equal('yaml', Ft('chart/values.yaml'))
  assert_equal('yaml', Ft('plain.yaml'))
enddef

def g:Test_HelmCommentstring()
  Ft('chart/templates/a.yaml')
  assert_equal('{{/* %s */}}', &commentstring)
enddef

def g:Test_UndotreeWindow()
  enew
  setline(1, 'a')
  Undotree
  assert_equal('undotree', &filetype)
  assert_equal(1, winnr(), 'undotree opens on the left')
  assert_equal(40, winwidth(0))
  h.Feed('q')
  assert_equal(1, winnr('$'), 'q closes it')
enddef
