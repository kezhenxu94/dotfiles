# Neovim → native Vim migration plan

Bring `config/vim` to feature parity with `config/nvim` using only native Vim
(Vim 9.1+) plus the pure-Vim9script LSP client `yegappan/lsp`. This is
**additive and non-destructive** — `config/nvim` and the nvim install stay in
place as a fallback.

> This file is the executable plan. The repo build environment has no GitHub
> egress, so the submodule and the tooling installs must be run on a machine
> with normal network access (your laptop). Every step below is something you
> run locally.

## Why

The dotfiles already carry two parallel editor configs, migrated piece by piece
off Neovim Lua plugins onto native Vim features (netrw, winpick, gitgutter,
async `:make`, fuzzy `:find`, sessions, tabline, native autocompletion). The
only remaining gap is the Neovim LSP/tooling stack. This plan closes it so a
real `vim` is a complete daily editor.

## What ports, what doesn't

| Neovim feature | Native Vim outcome |
|---|---|
| `nvim-lspconfig` / `vim.lsp` — diagnostics, code action, hover, goto, references, signature help, rename, completion source, document highlight, inlay hints | **Ports** → `yegappan/lsp`. Near-complete parity. |
| LSP completion feeding the popup menu | **Ports** → yegappan/lsp `autoComplete` + the already-configured native `completeopt=fuzzy,menuone,noselect,popup` / `set autocomplete`. |
| `mason.nvim` — auto-install + version management of tools | **Cannot port** (no in-editor manager). Replaced by static `packages/` installers; servers must be on `$PATH`. |
| `nvim-treesitter` — AST highlight, fold, indent, textobjects | **Cannot port.** Falls back to Vim's regex `syntax on` (already on), `cindent`/`smartindent` + `foldmethod=indent` (already set). Accepted loss: no AST highlight/fold/incremental-selection/TS textobjects. |
| `conform.nvim` — format-on-save (stylua/prettier/gofmt/shfmt/black/jq/yq/eslint_d) | **Ports** → native `BufWritePre` async formatter harness, LSP-format fallback. |
| `nvim-lint` | Currently a **no-op** (autocmd registered, `linters_by_ft` never set) — nothing to port. Optional native lint-on-save can be added later. |
| `nvim-dap` | **Dropped** by decision. No Vim debugger. |
| `nvim-jdtls` extras — test method/class, organize imports, goto subject | **Partial.** Plain `jdtls` LSP ports (completion/diagnostics/goto/rename); the nvim-jdtls-specific test/debug commands do not. |
| `lazydev.nvim`, `nvim.difftool` | nvim-only, irrelevant to Vim — dropped. |
| `vim-helm` | Plain Vim — add as a submodule if helm syntax highlighting is wanted. |

## Decisions (locked in)

- **LSP engine:** `yegappan/lsp` (pure Vim9script).
- **Debugging:** dropped.
- **Tooling install:** `packages/install/packages/` scripts (Mason replacement).
- **nvim fate:** keep `config/nvim` untouched.

## Critical isolation rule

`config/vim` is on Neovim's `runtimepath`/`packpath` (see `config/nvim/init.lua`).
To avoid a second LSP client loading inside nvim:

1. Install the plugin under `pack/vendor/opt/` (NOT `start/`) so it does not
   auto-load.
2. `packadd` it and source the whole LSP module only when `!has('nvim')`.

`vimrc` is never read by nvim, so sourcing the module from there is already safe;
the `opt/` placement is the second belt-and-braces guard.

---

## Step 1 — add the LSP client as a submodule (run locally)

```sh
cd ~/dotfiles
git submodule add https://github.com/yegappan/lsp config/vim/pack/vendor/opt/lsp
git commit -am "feat(vim): add yegappan/lsp submodule (opt) for native LSP"
```

This appends the matching stanza to `.gitmodules` automatically, mirroring the
existing fugitive/gitgutter/copilot entries (but `opt/`, not `start/`).

## Step 2 — create `config/vim/config/lsp/` (4 files)

### `config/vim/config/lsp/init.vim`

```vim
" Native LSP via yegappan/lsp. Loaded only in real Vim; nvim uses its own stack.
if has('nvim') | finish | endif
if !isdirectory($XDG_CONFIG_HOME . '/vim/pack/vendor/opt/lsp')
  finish
endif

packadd lsp

call LspOptionsSet({
  \ 'autoComplete': v:true,
  \ 'completionMatcher': 'fuzzy',
  \ 'showSignature': v:true,
  \ 'echoSignature': v:false,
  \ 'autoHighlight': v:true,
  \ 'autoHighlightDiags': v:true,
  \ 'showDiagWithVirtualText': v:true,
  \ 'showDiagWithSign': v:true,
  \ 'showInlayHints': v:true,
  \ 'usePopupInCodeAction': v:true,
  \ 'useBufferCompletion': v:false,
  \ 'diagSignErrorText': "",
  \ 'diagSignWarningText': "",
  \ 'diagSignInfoText': "",
  \ 'diagSignHintText': "",
  \ })

source $XDG_CONFIG_HOME/vim/config/lsp/servers.vim
source $XDG_CONFIG_HOME/vim/config/lsp/keymaps.vim
source $XDG_CONFIG_HOME/vim/config/lsp/format.vim
```

### `config/vim/config/lsp/servers.vim`

One `LspAddServer` entry per language, translated from
`config/nvim/lua/config/lsp/languages.lua` and `config/nvim/after/lsp/*.lua`.
Each `path` must resolve on `$PATH` (Step 4 installs them).

```vim
let s:vue_ls = expand($HOME . '/usr/local/lib/node_modules/@vue/language-server')

call LspAddServer([
  \ #{ name: 'lua_ls', filetype: ['lua'], path: 'lua-language-server',
  \    initializationOptions: #{}, workspaceConfig: #{
  \      Lua: #{ completion: #{ callSnippet: 'Replace' } } } },
  \ #{ name: 'gopls', filetype: ['go', 'gomod', 'gowork'], path: 'gopls', args: ['serve'] },
  \ #{ name: 'rust_analyzer', filetype: ['rust'], path: 'rust-analyzer', syncInit: v:true },
  \ #{ name: 'pyright', filetype: ['python'], path: 'pyright-langserver', args: ['--stdio'] },
  \ #{ name: 'bashls', filetype: ['sh', 'bash'], path: 'bash-language-server', args: ['start'] },
  \ #{ name: 'yamlls', filetype: ['yaml'], path: 'yaml-language-server', args: ['--stdio'] },
  \ #{ name: 'terraformls', filetype: ['terraform', 'tf'], path: 'terraform-ls', args: ['serve'] },
  \ #{ name: 'tailwindcss', filetype: ['html', 'css', 'javascriptreact', 'typescriptreact', 'vue'], path: 'tailwindcss-language-server', args: ['--stdio'] },
  \ #{ name: 'markdown_oxide', filetype: ['markdown'], path: 'markdown-oxide' },
  \ #{ name: 'helm_ls', filetype: ['helm'], path: 'helm_ls', args: ['serve'] },
  \ #{ name: 'docker_ls', filetype: ['dockerfile'], path: 'docker-language-server', args: ['start', '--stdio'] },
  \ #{ name: 'gh_actions', filetype: ['yaml.github'], path: 'gh-actions-language-server', args: ['--stdio'] },
  \ #{ name: 'vtsls', filetype: ['javascript', 'javascriptreact', 'typescript', 'typescriptreact', 'vue'],
  \    path: 'vtsls', args: ['--stdio'],
  \    workspaceConfig: #{ vtsls: #{ tsserver: #{ globalPlugins: [
  \      #{ name: '@vue/typescript-plugin', location: s:vue_ls, languages: ['vue'], configNamespace: 'typescript' } ] } } } },
  \ #{ name: 'jdtls', filetype: ['java'], path: 'jdtls',
  \    workspaceConfig: #{ java: #{ configuration: #{ runtimes: [
  \      #{ name: 'JavaSE-17', path: expand('~/.local/share/mise/installs/java/17/') },
  \      #{ name: 'JavaSE-21', path: expand('~/.local/share/mise/installs/java/21/') } ] } } } },
  \ ])
```

Notes:
- `#{...}` is Vim's literal-dict syntax (Vim 8.1.1705+), fine in legacy `.vim`.
- jdtls here is plain LSP. The nvim-jdtls test/organize-imports/goto-subject
  commands are intentionally not ported (no Vim equivalent). The lombok agent +
  JVM args from `config/nvim/after/ftplugin/java.lua` can be reproduced in a
  `config/vim/ftplugin/java.vim` if jdtls needs them (`let $JDTLS_JVM_ARGS = ...`).
- Adjust each `path` if you install servers somewhere not on `$PATH`.

### `config/vim/config/lsp/keymaps.vim`

Buffer-local maps mirroring the Neovim-default verbs you're used to, set when a
server attaches. Code-action mapping matches `config/nvim/lua/config/lsp/lsp.lua`.

```vim
function! s:OnLspAttach() abort
  setlocal omnifunc=lsp#lsp#OmniFunc
  nnoremap <buffer><silent> K        :LspHover<CR>
  nnoremap <buffer><silent> grr      :LspShowReferences<CR>
  nnoremap <buffer><silent> gri      :LspGotoImpl<CR>
  nnoremap <buffer><silent> grn      :LspRename<CR>
  nnoremap <buffer><silent> gd       :LspGotoDefinition<CR>
  nnoremap <buffer><silent> gD       :LspGotoDeclaration<CR>
  nnoremap <buffer><silent> gy       :LspGotoTypeDef<CR>
  nnoremap <buffer><silent> gO       :LspDocumentSymbol<CR>
  nnoremap <buffer><silent> <leader>ca :LspCodeAction<CR>
  nnoremap <buffer><silent> [d       :LspDiagPrev<CR>
  nnoremap <buffer><silent> ]d       :LspDiagNext<CR>
  nnoremap <buffer><silent> <leader>tih :LspInlayHints toggle<CR>
endfunction

augroup kzx_lsp_attach
  autocmd!
  autocmd User LspAttached call s:OnLspAttach()
augroup END
```

### `config/vim/config/lsp/format.vim`

Async format-on-save replicating `config/nvim/lua/config/lsp/formatter.lua`.
Reuse the async job pattern already proven in `config/vim/config/editor/make.vim`
(`job_start` + temp file swap). Formatter map below matches conform exactly.

```vim
" filetype -> list of CLI formatter argv templates ({} = current file path)
let s:formatters = {
  \ 'lua':            [['stylua', '-']],
  \ 'go':             [['gofmt']],
  \ 'json':           [['jq', '.']],
  \ 'sh':             [['shfmt']],
  \ 'bash':           [['shfmt']],
  \ 'yaml':           [['yq', '-P', '.']],
  \ 'python':         [['black', '-', '-q']],
  \ 'typescript':     [['eslint_d', '--stdin', '--fix-to-stdout'], ['prettier', '--stdin-filepath', '%']],
  \ 'typescriptreact':[['eslint_d', '--stdin', '--fix-to-stdout'], ['prettier', '--stdin-filepath', '%']],
  \ 'vue':            [['eslint_d', '--stdin', '--fix-to-stdout'], ['prettier', '--stdin-filepath', '%']],
  \ 'javascript':     [['prettierd', '%']],
  \ }

let g:disable_autoformat = get(g:, 'disable_autoformat', 0)

function! s:Format() abort
  if g:disable_autoformat || get(b:, 'disable_autoformat', 0) | return | endif
  let l:ft = &filetype
  if has_key(s:formatters, l:ft)
    " Pipe buffer through each formatter in order; on success replace buffer,
    " preserving cursor. (See make.vim for the job/stdout collection pattern.)
    call s:RunChainedFormatters(s:formatters[l:ft])
  elseif exists(':LspFormat') == 2
    " Fallback to LSP formatting when no CLI formatter is configured.
    silent! LspFormat
  endif
endfunction

augroup kzx_format_on_save
  autocmd!
  autocmd BufWritePre * call s:Format()
augroup END

nnoremap <silent> <leader>tff :let b:disable_autoformat = !get(b:, 'disable_autoformat', 0)<CR>
```

> `s:RunChainedFormatters` is the one helper to write: feed the buffer to each
> argv on stdin, capture stdout, and on a clean exit replace the buffer lines
> while keeping the view (`winsaveview`/`winrestview`). Model it on the
> `job_start` + `out_cb`/`exit_cb` flow in `config/vim/config/editor/make.vim`.
> `%` in an argv is expanded to the file path; bare `-`/`.` mean read stdin.
> For the simplest first cut you may run formatters synchronously with
> `systemlist()` on `BufWritePre` — async is a nicety, not required for parity.

## Step 3 — wire into `vimrc`

In `config/vim/vimrc`, after the editor module source line, add:

```vim
if !has('nvim')
  source $XDG_CONFIG_HOME/vim/config/lsp/init.vim
endif
```

## Step 4 — tooling installers (Mason replacement)

Add numbered scripts under `packages/install/packages/` following the existing
conventions (`pkg_name`/`pkg_version`, `check_installed` guard, `try_package_manager`,
helpers in `packages/install/lib/helpers.sh`). Group by ecosystem. Each should
no-op if its toolchain (npm/go/cargo/pip) is missing.

Tools needed (from `config/nvim/lua/config/lsp/languages.lua`):

- **npm / node** (`npm i -g`): `bash-language-server`, `@vtsls/language-server`
  (`vtsls`), `yaml-language-server`, `@vue/language-server`,
  `@tailwindcss/language-server`, `pyright`, `vscode-langservers-extracted`,
  `prettier`, `@fsouza/prettierd`, `eslint_d`, `jsonlint`, `markdownlint-cli`,
  `@github/gh-actions-language-server`, `dockerfile-language-server-nodejs`.
- **go** (`go install`): `gopls`, `mvdan.cc/sh/v3/cmd/shfmt`,
  `github.com/rhysd/actionlint/cmd/actionlint`.
- **cargo** (`cargo install`): `rust-analyzer` (or via `rustup component add`),
  `stylua`, `markdown-oxide`.
- **pip / uv**: `black`, `yamllint` (pyright also available via pip).
- **system pkg / release binaries**: `jdtls`, `lua-language-server`, `helm-ls`,
  `terraform-ls`, `jq`, `yq`, `shellcheck`.

Example (`packages/install/packages/80-lsp-npm.sh`):

```sh
#!/usr/bin/env bash
pkg_name="lsp-npm"
pkg_version="latest"

install_lsp_npm() {
  check_installed npm || { echo "npm not found; skipping node LSP tools"; return 0; }
  local pkgs=(
    bash-language-server "@vtsls/language-server" yaml-language-server
    "@vue/language-server" "@tailwindcss/language-server" pyright
    vscode-langservers-extracted prettier "@fsouza/prettierd" eslint_d
    jsonlint markdownlint-cli "@github/gh-actions-language-server"
    dockerfile-language-server-nodejs
  )
  npm install -g "${pkgs[@]}"
}

install_lsp_npm
```

Add sibling scripts `81-lsp-go.sh`, `82-lsp-cargo.sh`, `83-lsp-pip.sh`, and
`84-lsp-bin.sh` (jdtls/lua-ls/helm-ls/terraform-ls/jq/yq/shellcheck) in the same
shape. Comment which language each tool serves.

> Note: the nvim PATH entry `$HOME/.local/share/nvim/mason/bin` in `zshenv` can
> stay — it's harmless. New tools land in npm/go/cargo/`$HOME/.bin` global bins,
> all already on `$PATH`.

## Step 5 — verify

1. **No nvim regression:** `nvim` still loads its Lua LSP stack; confirm
   `pack/vendor/opt/lsp` is NOT loaded (`opt/` + `has('nvim')` guard).
2. **Vim loads clean:** `vim` (9.1+) opens with no errors;
   `:echo exists(':LspServers')` → `2`; `:LspServers` lists configured servers.
3. **Per-language LSP:** open `.lua`/`.go`/`.ts`/`.py`/`.sh`/`.yaml` in a real
   project — server attaches, diagnostics show, `K` hover works, completion
   popup fills, `grn`/`<leader>ca` work.
4. **Format-on-save:** `:w` a `.lua` (stylua), `.go` (gofmt), `.py` (black),
   `.ts` (prettier) file → reformats; `<leader>tff` toggles it off.
5. **Tooling on PATH:** `command -v gopls bash-language-server stylua black` etc.
6. **Accepted losses confirmed:** highlighting is `syntax on` (no treesitter);
   Java has LSP but not the nvim-jdtls test/debug commands.

## Optional follow-ups

- **Native lint-on-save** (replaces the currently-unused nvim-lint): a
  `config/vim/config/lsp/lint.vim` `BufWritePost` async harness running
  shellcheck/yamllint/jsonlint/markdownlint/actionlint into the location list
  with signs — reuse the make.vim job pattern.
- **vim-helm** submodule for helm template syntax, if desired.
- **Java ftplugin** (`config/vim/ftplugin/java.vim`) to set the lombok
  `-javaagent` JVM args if jdtls needs them.
