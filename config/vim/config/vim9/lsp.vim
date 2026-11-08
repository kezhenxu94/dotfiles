vim9script
# Port of config/nvim/lua/config/lsp/lsp.lua and config/nvim/{lsp,after/lsp}/*.lua
# on top of yegappan/lsp.

packadd lsp

import autoload 'lsp/buffer.vim' as lspbuf
import autoload 'lsp/util.vim' as lsputil

g:LspOptionsSet({
  # Like vim.lsp.completion's autotrigger: omni completion pops up on the
  # server's trigger characters (see TriggerCompletion), not on every key.
  autoComplete: false,
  omniComplete: true,
  # Servers send snippets (vue_ls even sends "$1" as plain text otherwise);
  # without a snippet engine they are inserted as plain text, keeping the
  # placeholder text, e.g. v-if="" or foo(a).
  snippetSupport: true,
  completionMatcher: 'fuzzy',
  # Full kind names in the menu, as in Neovim.
  customCompletionKinds: true,
  completionKinds: ['Text', 'Method', 'Function', 'Constructor', 'Field', 'Variable',
    'Class', 'Interface', 'Module', 'Property', 'Unit', 'Value', 'Enum', 'Keyword',
    'Snippet', 'Color', 'File', 'Reference', 'Folder', 'EnumMember', 'Constant',
    'Struct', 'Event', 'Operator', 'TypeParameter']
    ->reduce((acc, k) => acc->extend({[k]: k}), {}),
  showInlayHints: true,
  semanticHighlight: true,
  # Like vim.lsp.enable(), skip servers that are not installed.
  ignoreMissingServer: true,
  # One server per workspace root (Neovim starts one client per root_dir),
  # so each tab/worktree gets its own servers.
  serverPerRoot: true,
  # Full-text didChange right after didOpen crashes vtsls; send ranges.
  incrementalSync: true,
  # References/implementations go to the quickfix list, as in Neovim.
  useQuickfixForLocations: true,
  # Ask every attached server for hover and completion and merge the
  # results, as Neovim does (e.g. vue_ls + vtsls, yamlls + gh_actions_ls).
  hoverAllServers: true,
  completionAllServers: true,
})

# yegappan/lsp asks one server per feature (Neovim merges all clients).
# Servers sharing filetypes with tailwindcss/yamlls claim the features so they
# win regardless of attach order; diagnostics are still merged from all.
const features = ['callHierarchy', 'codeAction', 'codeLens', 'completion',
  'declaration', 'definition', 'documentFormatting', 'documentHighlight',
  'documentRangeFormatting', 'documentSymbol', 'foldingRange', 'hover',
  'implementation', 'inlayHint', 'references', 'rename', 'selectionRange',
  'semanticTokens', 'signatureHelp', 'typeDefinition', 'typeHierarchy']
export def Primary(server: dict<any>): dict<any>
  server.features = features->copy()->reduce((acc, f) => acc->extend({[f]: true}), {})
  return server
enddef

def YamlLanguageId(): string
  return 'yaml'
enddef

def DockerLanguageId(): string
  if &filetype =~ 'yaml'
    return 'dockercompose'
  endif
  return &filetype == 'hcl.docker-bake' ? 'dockerbake' : &filetype
enddef

# Server -> client requests that yegappan/lsp does not implement.
def ReadFile(server: dict<any>, req: dict<any>)
  var path = req.params->get('path')
  var text: any = v:null
  if type(path) == v:t_string && filereadable(lsputil.LspUriToFile(path))
    text = readfile(lsputil.LspUriToFile(path), 'b')->join("\n")
  endif
  server.sendResponse(req, text, {})
enddef

def ShowDocument(server: dict<any>, req: dict<any>)
  execute $'edit {fnameescape(lsputil.LspUriToFile(req.params.uri))}'
  server.sendResponse(req, {success: true}, {})
enddef

const rust_settings = {lens: {
  debug: {enable: true},
  enable: true,
  implementations: {enable: true},
  references: {adt: {enable: true}, enumVariant: {enable: true}, method: {enable: true}, trait: {enable: true}},
  run: {enable: true},
  updateTest: {enable: true},
}}

g:LspAddServer([
  Primary({
    name: 'gopls', path: 'gopls', filetype: ['go', 'gomod', 'gowork', 'gotmpl'],
    rootSearch: ['go.work', 'go.mod', '.git/'],
    workspaceConfig: {gopls: {semanticTokens: true}},
  }),
  {
    name: 'yamlls', path: 'yaml-language-server', args: ['--stdio'],
    filetype: ['yaml', 'yaml.docker-compose', 'yaml.gitlab', 'yaml.helm-values', 'yaml.github-actions'],
    languageId: YamlLanguageId,
    rootSearch: ['.git/'],
    workspaceConfig: {
      redhat: {telemetry: {enabled: false}},
      yaml: {format: {enable: true}},
    },
  },
  Primary({
    name: 'bashls', path: 'bash-language-server', args: ['start'],
    filetype: ['sh', 'bash'],
    rootSearch: ['.git/'],
    workspaceConfig: {bashIde: {globPattern: $GLOB_PATTERN ?? '*@(.sh|.inc|.bash|.command)'}},
  }),
  Primary({
    name: 'rust_analyzer', path: 'rust-analyzer', filetype: ['rust'],
    rootSearch: ['Cargo.toml', 'rust-project.json', '.git/'],
    initializationOptions: rust_settings,
    workspaceConfig: {'rust-analyzer': rust_settings},
  }),
  Primary({
    name: 'pyright', path: 'pyright-langserver', args: ['--stdio'], filetype: ['python'],
    rootSearch: ['pyrightconfig.json', 'pyproject.toml', 'setup.py', 'setup.cfg',
      'requirements.txt', 'Pipfile', '.git/'],
    workspaceConfig: {
      pyright: {disableTaggedHints: true},
      python: {analysis: {autoSearchPaths: true, useLibraryCodeForTypes: true, diagnosticMode: 'openFilesOnly'}},
    },
  }),
  Primary({
    name: 'terraformls', path: 'terraform-ls', args: ['serve'],
    filetype: ['terraform', 'terraform-vars'],
    rootSearch: ['.terraform/', '.git/'],
  }),
  Primary({
    name: 'markdown_oxide', path: 'markdown-oxide', filetype: ['markdown'],
    rootSearch: ['.git/', '.obsidian/', '.moxide.toml'],
    customRequestHandlers: {'window/showDocument': ShowDocument},
  }),
  Primary({
    name: 'helm_ls', path: 'helm_ls', args: ['serve'], filetype: ['helm', 'yaml.helm-values'],
    rootSearch: ['Chart.yaml'],
  }),
  Primary({
    name: 'docker_language_server', path: 'docker-language-server', args: ['start', '--stdio'],
    filetype: ['dockerfile', 'yaml.docker-compose', 'hcl.docker-bake'],
    languageId: DockerLanguageId,
    rootSearch: ['Dockerfile', 'docker-compose.yaml', 'docker-compose.yml', 'compose.yaml',
      'compose.yml', 'docker-bake.json', 'docker-bake.hcl', 'docker-bake.override.json',
      'docker-bake.override.hcl'],
  }),
  Primary({
    name: 'gh_actions_ls', path: 'gh-actions-language-server', args: ['--stdio'],
    filetype: ['yaml.github-actions'],
    languageId: YamlLanguageId,
    initializationOptions: {},
    customRequestHandlers: {'actions/readFile': ReadFile},
  }),
  {
    name: 'tailwindcss', path: 'tailwindcss-language-server', args: ['--stdio'],
    filetype: ['aspnetcorerazor', 'astro', 'astro-markdown', 'blade', 'clojure',
      'django-html', 'htmldjango', 'edge', 'eelixir', 'elixir', 'ejs', 'erb', 'eruby',
      'gohtml', 'gohtmltmpl', 'haml', 'handlebars', 'hbs', 'html', 'htmlangular',
      'html-eex', 'heex', 'jade', 'leaf', 'liquid', 'markdown', 'mdx', 'mustache', 'njk',
      'nunjucks', 'php', 'razor', 'slim', 'twig', 'css', 'less', 'postcss', 'sass',
      'scss', 'stylus', 'sugarss', 'javascript', 'javascriptreact', 'reason',
      'rescript', 'typescript', 'typescriptreact', 'vue', 'svelte', 'templ'],
    # workspace_required: only start inside a project.
    runIfSearch: ['tailwind.config.js', 'tailwind.config.cjs', 'tailwind.config.mjs',
      'tailwind.config.ts', 'postcss.config.js', 'postcss.config.cjs',
      'postcss.config.mjs', 'postcss.config.ts', '.git/'],
    rootSearch: ['tailwind.config.js', 'tailwind.config.cjs', 'tailwind.config.mjs',
      'tailwind.config.ts', 'postcss.config.js', 'postcss.config.cjs',
      'postcss.config.mjs', 'postcss.config.ts', '.git/'],
    workspaceConfig: {
      editor: {tabSize: &tabstop},
      tailwindCSS: {
        validate: true,
        lint: {
          cssConflict: 'warning',
          invalidApply: 'error',
          invalidScreen: 'error',
          invalidVariant: 'error',
          invalidConfigPath: 'error',
          invalidTailwindDirective: 'error',
          recommendedVariantOrder: 'warning',
        },
        classAttributes: ['class', 'className', 'class:list', 'classList', 'ngClass'],
        includeLanguages: {
          eelixir: 'html-eex',
          elixir: 'phoenix-heex',
          eruby: 'erb',
          heex: 'phoenix-heex',
          htmlangular: 'html',
          templ: 'html',
        },
      },
    },
  },
])

# The servers below shell out while being configured, so they are registered
# on first use instead of slowing down every Vim startup.

var npm_root: string
def NpmRoot(): string
  if npm_root == null_string
    npm_root = system('npm root -g')->trim()
    if v:shell_error != 0
      npm_root = ''
    endif
  endif
  return npm_root
enddef

# vue_ls (hybrid mode) forwards TypeScript requests through vtsls.
def ForwardToTsserver(vue: dict<any>, notif: dict<any>, retries = 0)
  var [id, command, payload] = notif.params[0]
  var bnr = lspbuf.BufGetServerBufnrs(vue)->get(0, bufnr())
  var ts = lspbuf.BufLspServersGet(bnr)->copy()->filter((_, s) => s.name == 'vtsls')
  if ts->empty() || !ts[0].ready
    # vtsls may attach a little later than vue_ls.
    if retries < 10
      timer_start(100, (_) => ForwardToTsserver(vue, notif, retries + 1))
    else
      echoerr 'Could not find `vtsls` lsp client required by `vue_ls`.'
    endif
    return
  endif
  ts[0].rpc_a('workspace/executeCommand', {
    command: 'typescript.tsserverRequest',
    arguments: [command, payload],
  }, (_, result, _) => {
    var body = type(result) == v:t_dict ? result->get('body', v:null) : v:null
    # sendNotification() only takes dict params.
    vue.sendMessage({jsonrpc: '2.0', method: 'tsserver/response', params: [[id, body]]})
  })
enddef

def AddTsServers()
  var root = NpmRoot()
  var vue_plugin = $'{root}/@vue/language-server'
  var tsdk = $'{root}/@vtsls/language-server/node_modules/typescript/lib'
  var vtsls: dict<any> = {
    name: 'vtsls', path: 'vtsls', args: ['--stdio'],
    filetype: ['javascript', 'javascriptreact', 'typescript', 'typescriptreact', 'vue'],
    initializationOptions: {hostInfo: 'vim'},
    rootSearch: ['package-lock.json', 'yarn.lock', 'pnpm-lock.yaml', 'bun.lockb', 'bun.lock', '.git/'],
    runUnlessSearch: ['deno.json', 'deno.jsonc', 'deno.lock'],
    workspaceConfig: {vtsls: {tsserver: {globalPlugins: isdirectory(vue_plugin) ? [{
      name: '@vue/typescript-plugin',
      location: vue_plugin,
      languages: ['vue'],
      configNamespace: 'typescript',
    }] : []}}},
  }
  var vue: dict<any> = {
    # vtsls (with the Vue plugin) answers TypeScript features in .vue files;
    # vue_ls owns these, and completion/hover are merged from both.
    features: {documentSymbol: true, foldingRange: true, semanticTokens: true, documentHighlight: true},
    name: 'vue_ls', path: 'vue-language-server',
    args: ['--stdio'] + (isdirectory(tsdk) ? [$'--tsdk={tsdk}'] : []),
    filetype: ['vue'],
    rootSearch: ['package.json'],
    customNotificationHandlers: {'tsserver/request': ForwardToTsserver},
  }
  g:LspAddServer([vue, Primary(vtsls)])
enddef

augroup kzx_lsp_lazy
  autocmd!
  autocmd FileType javascript,javascriptreact,typescript,typescriptreact,vue ++once AddTsServers()
augroup END

def BufServer(name: string): dict<any>
  return lspbuf.BufLspServersGet(bufnr())->copy()->filter((_, s) => s.name == name)->get(0, {})
enddef

def ExecCommand(name: string, command: string, args: list<any>)
  var server = BufServer(name)
  if !server->empty()
    server.rpc_a('workspace/executeCommand', {command: command, arguments: args}, (_, _, _) => 0)
  endif
enddef

# Open omni completion after a trigger character (minus " ", as in nvim).
def TriggerCompletion()
  if v:char != ' ' && lspbuf.CurbufGetServers()->copy()
      ->filter((_, s) => s->get('completionTriggerChars', [])->index(v:char) >= 0)->len() > 0
    feedkeys("\<C-x>\<C-o>", 'n')
  endif
enddef

def OnAttach()
  autocmd! kzx_lsp_attach InsertCharPre <buffer>
  autocmd kzx_lsp_attach InsertCharPre <buffer> TriggerCompletion()
  setlocal tagfunc=lsp#lsp#TagFunc
  setlocal formatexpr=lsp#lsp#FormatExpr()

  # Neovim's default LSP mappings.
  nnoremap <buffer> K <Cmd>LspHover<CR>
  nnoremap <buffer> grn <Cmd>LspRename<CR>
  nnoremap <buffer> gra <Cmd>LspCodeAction<CR>
  xnoremap <buffer> gra :LspCodeAction<CR>
  nnoremap <buffer> grr <Cmd>LspShowReferences<CR>
  nnoremap <buffer> gri <ScriptCmd>Implementations()<CR>
  nnoremap <buffer> grt <Cmd>LspGotoTypeDef<CR>
  nnoremap <buffer> gO <ScriptCmd>DocumentSymbols()<CR>
  xnoremap <buffer> an <Cmd>LspSelectionExpand<CR>
  xnoremap <buffer> in <Cmd>LspSelectionShrink<CR>
  onoremap <buffer> an :<C-u>normal van<CR>
  onoremap <buffer> in :<C-u>normal vin<CR>
enddef

def Location(server: dict<any>, loc: dict<any>): dict<any>
  # Location or LocationLink.
  var uri = loc->get('uri', loc->get('targetUri', ''))
  var range = loc->get('range', loc->get('targetSelectionRange', {}))
  var fname = lsputil.LspUriToFile(uri)
  var lnum = range.start.line + 1
  var text = bufloaded(fname) ? getbufline(fname, lnum)->get(0, '')
    : filereadable(fname) ? readfile(fname, '', lnum)->get(-1, '') : ''
  return {filename: fname, lnum: lnum, col: range.start.character + 1, text: text->trim()}
enddef

# gri: implementations in the quickfix list, even a single one (vim.lsp.buf.implementation).
def Implementations()
  var server = lspbuf.CurbufGetServer('implementation')
  if server->empty()
    echo 'No implementation provider'
    return
  endif
  server.rpc_a('textDocument/implementation', server.getTextDocPosition(false), (_, result, _) => {
    var locs = type(result) == v:t_list ? result : type(result) == v:t_dict ? [result] : []
    if locs->empty()
      echo 'No implementations found'
      return
    endif
    setqflist([], ' ', {title: 'Implementations', items: locs->mapnew((_, l) => Location(server, l))})
    copen
  })
enddef

# gO: document symbols in the location list (vim.lsp.buf.document_symbol).
def DocumentSymbols()
  var server = lspbuf.CurbufGetServer('documentSymbol')
  if server->empty()
    echo 'No document symbol provider'
    return
  endif
  var bnr = bufnr()
  var fname = expand('%:p')
  server.rpc_a('textDocument/documentSymbol', {textDocument: {uri: lsputil.LspBufnrToUri(bnr)}}, (_, result, _) => {
    var items: list<dict<any>> = []
    var Add: func
    Add = (symbols: list<any>) => {
      for s in symbols
        var r = s->has_key('selectionRange') ? s.selectionRange : s->has_key('range') ? s.range : s.location.range
        items->add({bufnr: bnr, lnum: r.start.line + 1, col: r.start.character + 1, text: $'[{lsp#symbol#SymbolKindToName(s.kind)}] {s.name}'})
        Add(s->get('children', []) ?? [])
      endfor
      return 0
    }
    Add(type(result) == v:t_list ? result : [])
    setloclist(bufwinid(bnr), [], ' ', {title: $'Symbols in {fnamemodify(fname, ':t')}', items: items})
    win_execute(bufwinid(bnr), 'lopen')
  })
enddef

def PyrightSetPythonPath(path: string)
  var server = BufServer('pyright')
  if !server->empty()
    server.workspaceConfig.python.pythonPath = path
    server.sendWorkspaceConfig()
  endif
enddef

def CargoReload()
  var server = BufServer('rust_analyzer')
  if !server->empty()
    server.rpc_a('rust-analyzer/reloadWorkspace', null, (..._) => 0)
  endif
enddef

def MarkdownOxideCommands()
  for cmd in ['today', 'tomorrow', 'yesterday']
    execute $'command! -buffer Lsp{cmd->substitute('^.', '\u&', '')} ExecCommand("markdown_oxide", "jump", ["{cmd}"])'
  endfor
enddef

def ShowProgress()
  var items = values(g:LspProgress)
  var msg = items->empty() ? '✔ Done' : printf('[%s] %s %s%s', items[-1].serverName,
    items[-1].title, items[-1].message, items[-1].percentage >= 0 ? $' ({items[-1].percentage}%)' : '')
  echo msg[: &columns - 13]
enddef

augroup kzx_lsp_attach
  autocmd!
  autocmd User LspAttached OnAttach()
  autocmd User LspProgressUpdate ShowProgress()
  autocmd FileType markdown MarkdownOxideCommands()
  autocmd FileType python command! -buffer LspPyrightOrganizeImports ExecCommand('pyright', 'pyright.organizeimports', [lsp#util#LspBufnrToUri(bufnr())])
  autocmd FileType python command! -buffer -nargs=1 -complete=file LspPyrightSetPythonPath PyrightSetPythonPath(<q-args>)
  autocmd FileType rust command! -buffer LspCargoReload CargoReload()
augroup END

# yegappan/lsp only toggles inlay hints globally.
nnoremap <leader>tih <Cmd>LspInlayHints toggle<CR>
nnoremap <leader>tiH <Cmd>LspInlayHints toggle<CR>
