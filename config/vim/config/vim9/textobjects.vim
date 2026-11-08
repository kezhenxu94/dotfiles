vim9script
# Port of config/nvim/lua/config/lsp/treesitter.lua. Vim has no tree-sitter,
# so the syntax tree comes from the language server instead: folds from
# textDocument/foldingRange, function/class textobjects and motions from
# textDocument/documentSymbol (highlighting uses semantic tokens, see lsp.vim).
# Without a server, Vim's syntax, indent folding and builtin ]m/[m/]c/[c apply.

import autoload 'lsp/buffer.vim' as lspbuf
import autoload 'lsp/util.vim' as lsputil

const FUNCTION_KINDS = [6, 9, 12]     # Method, Constructor, Function
const CLASS_KINDS = [5, 10, 11, 23]   # Class, Enum, Interface, Struct

# rust-analyzer reports impl blocks as Object, which tree-sitter treats as
# classes (elsewhere Object means e.g. a YAML mapping).
def ClassKinds(ft = &filetype): list<number>
  return ft == 'rust' ? CLASS_KINDS + [19] : CLASS_KINDS
enddef

# --- Folding -----------------------------------------------------------------

def FoldExpr(): string
  return get(b:, 'kzx_folds', [])->get(v:lnum - 1, '=')
enddef

# Closing lines that tree-sitter folds include but many servers leave out.
const CLOSER = '^\s*\%([]})]\|end\>\)'

def FoldReply(bnr: number, ranges: any)
  if type(ranges) != v:t_list || !bufexists(bnr)
    return
  endif
  var n = getbufinfo(bnr)[0].linecount
  # One fold per start line (the largest), like tree-sitter.
  var ends: dict<number> = {}
  for r in ranges
    var end = r.endLine
    if end + 1 < n && getbufline(bnr, end + 1)[0] !~ CLOSER && getbufline(bnr, end + 2)[0] =~ CLOSER
      end += 1
    endif
    if end > r.startLine && r.startLine < n
      ends[r.startLine] = max([ends->get(r.startLine, 0), min([end, n - 1])])
    endif
  endfor
  var delta = repeat([0], n + 1)
  for [start, end] in ends->items()
    delta[str2nr(start)] += 1
    delta[end + 1] -= 1
  endfor
  var folds: list<string> = []
  var level = 0
  for i in range(n)
    level += delta[i]
    folds->add(ends->has_key(i) ? $'>{level}' : string(level))
  endfor
  setbufvar(bnr, 'kzx_folds', folds)
  for w in win_findbuf(bnr)
    # Re-setting foldexpr makes Vim recompute the folds.
    win_execute(w, $'setlocal foldmethod=expr foldexpr={expand('<SID>')}FoldExpr()')
  endfor
enddef

# Fold ranges from documentSymbol (functions and classes) for servers without
# foldingRange, e.g. pyright.
def SymbolFolds(bnr: number, symbols: any)
  var ranges: list<dict<number>> = []
  var Collect: func
  Collect = (items: list<any>) => {
    for s in items
      var r = s->has_key('range') ? s.range : s.location.range
      if (FUNCTION_KINDS + ClassKinds(getbufvar(bnr, '&filetype')))->index(s.kind) >= 0
        # From the declaration line, not a leading decorator/comment.
        ranges->add({startLine: s->get('selectionRange', r).start.line, endLine: r.end.line})
      endif
      Collect(s->get('children', []) ?? [])
    endfor
    return 0
  }
  Collect(type(symbols) == v:t_list ? symbols : [])
  FoldReply(bnr, ranges)
enddef

def UpdateFolds(bnr: number)
  var params = {textDocument: {uri: lsputil.LspBufnrToUri(bnr)}}
  var server = lspbuf.BufLspServerGet(bnr, 'foldingRange')
  if !server->empty()
    listener_flush(bnr)
    server.rpc_a('textDocument/foldingRange', params, (_, r, _) => FoldReply(bnr, r))
    return
  endif
  # Without foldingRange, symbols replace indent folding (but not a fold
  # method set for the filetype, e.g. syntax folding for sh).
  server = lspbuf.BufLspServerGet(bnr, 'documentSymbol')
  if !server->empty() && (exists('b:kzx_folds') || getwinvar(bufwinid(bnr), '&foldmethod') == 'indent')
    listener_flush(bnr)
    server.rpc_a('textDocument/documentSymbol', params, (_, r, _) => SymbolFolds(bnr, r))
  endif
enddef

var fold_timers: dict<number> = {}
def ScheduleFolds(bnr: number)
  timer_stop(fold_timers->get(bnr, -1))
  fold_timers[bnr] = timer_start(300, (_) => UpdateFolds(bnr))
enddef

def SetupFolds()
  var bnr = bufnr()
  UpdateFolds(bnr)
  execute $'autocmd! kzx_lsp_folds * <buffer={bnr}>'
  execute $'autocmd kzx_lsp_folds TextChanged,InsertLeave <buffer={bnr}> ScheduleFolds({bnr})'
  execute $'autocmd kzx_lsp_folds BufWinEnter <buffer={bnr}> if exists("b:kzx_folds") | setlocal foldmethod=expr foldexpr={expand('<SID>')}FoldExpr() | endif'
enddef

augroup kzx_lsp_folds
  autocmd!
  autocmd User LspAttached SetupFolds()
augroup END

# --- Symbols -----------------------------------------------------------------

# Flattened symbols of the current buffer: {kind, start: [lnum, col], end:
# [lnum, col]} with 1-based character positions, end exclusive.
def Symbols(): list<dict<any>>
  if get(b:, 'kzx_symbols_tick', -1) == b:changedtick
    return b:kzx_symbols
  endif
  var server = lspbuf.CurbufGetServer('documentSymbol')
  if server->empty()
    return []
  endif
  var bnr = bufnr()
  listener_flush()
  var reply = server.rpc('textDocument/documentSymbol',
    {textDocument: {uri: lsputil.LspBufnrToUri(bnr)}}, {timeout: 5000})
  var symbols: list<dict<any>> = []
  Flatten(server, bnr, reply->get('result', []) ?? [], symbols)
  symbols->sort((a, b) => a.start[0] - b.start[0] ?? a.start[1] - b.start[1])
  # Cache only real replies: a busy server's timeout must not stick until
  # the next change.
  if reply->has_key('result')
    b:kzx_symbols = symbols
    b:kzx_symbols_tick = b:changedtick
  endif
  return symbols
enddef

def Pos(p: dict<number>): list<number>
  return [p.line + 1, p.character + 1]
enddef

def FirstNonBlank(bnr: number, lnum: number): number
  return strcharlen(getbufline(bnr, lnum)->get(0, '')->matchstr('^\s*')) + 1
enddef

def Flatten(server: dict<any>, bnr: number, items: list<any>, symbols: list<dict<any>>, parent_kind = 0)
  for s in items
    # DocumentSymbol has "range", SymbolInformation has "location.range".
    var range = s->has_key('range') ? s.range : s.location.range
    var name = s->get('selectionRange', range)
    if server.needOffsetEncoding
      server.decodeRange(bnr, range)
      if name isnot range
        server.decodeRange(bnr, name)
      endif
    endif
    var start = Pos(range.start)
    if s->has_key('selectionRange')
      # Start at the declaration line like tree-sitter: not at a leading
      # comment/javadoc/decorator, and not at the name ("type Foo struct").
      start = [name.start.line + 1, FirstNonBlank(bnr, name.start.line + 1)]
      # Lua "M.f = function(...)": the function starts at "function".
      var assigned = getbufline(bnr, start[0])->get(0, '')->matchstrpos('=\s*\zsfunction\>')
      if getbufvar(bnr, '&filetype') == 'lua' && assigned[1] >= 0
        start[1] = charidx(getbufline(bnr, start[0])[0], assigned[1]) + 1
      endif
    endif
    # Go interface method specs aren't functions for tree-sitter.
    if !(getbufvar(bnr, '&filetype') == 'go' && parent_kind == 11)
      symbols->add({kind: s.kind, start: start, end: Pos(range.end),
        name_end: s->has_key('selectionRange') ? Pos(name.end) : start})
    endif
    Flatten(server, bnr, s->get('children', []) ?? [], symbols, s.kind)
  endfor
enddef

def Before(a: list<number>, b: list<number>): bool
  return a[0] < b[0] || a[0] == b[0] && a[1] < b[1]
enddef

def Cursor(): list<number>
  return [line('.'), charcol('.')]
enddef

# Last character covered by an exclusive end position.
def LastChar(pos: list<number>): list<number>
  if pos[1] > 1
    return [pos[0], pos[1] - 1]
  endif
  return [pos[0] - 1, max([strcharlen(getline(pos[0] - 1)), 1])]
enddef

# --- Textobjects ---------------------------------------------------------------

def SelectRange(start: list<number>, end: list<number>, wise = 'v')
  if mode() =~# "[vV\<C-v>]"
    execute "normal! \<Esc>"
  endif
  setcursorcharpos(start[0], start[1])
  execute $'normal! {wise}'
  setcursorcharpos(end[0], end[1])
enddef

def Select(kinds: list<number>, inner: bool)
  var cur = Cursor()
  var target: dict<any> = {}
  for s in Symbols()->copy()->filter((_, s) => kinds->index(s.kind) >= 0)
    if !Before(cur, s.start) && Before(cur, s.end)
      target = s   # sorted by start, so the last match is the innermost
    elseif target->empty() && Before(cur, s.start)
      target = s   # lookahead: the next one after the cursor
      break
    endif
  endfor
  if target->empty()
    return
  endif
  if !inner
    SelectRange(target.start, LastChar(target.end))
    return
  endif

  # Markdown sections: the heading text.
  if &filetype == 'markdown'
    var heading = getline(target.start[0])
    var text = heading->matchstrpos('^#\+\s*\zs.*\S')
    if text[1] >= 0
      SelectRange([target.start[0], charidx(heading, text[1]) + 1], [target.start[0], charidx(heading, text[2] - 1) + 1])
    endif
    return
  endif

  # Inner: the body between the braces after the name, or the indented body
  # for brace-less languages (where "{" starts a table/dict literal).
  var last = LastChar(target.end)
  setcursorcharpos(target.name_end[0], target.name_end[1])
  const skip = 'synIDattr(synID(line("."), col("."), 0), "name") =~? "string\\|comment"'
  var open = BRACELESS->index(&filetype) >= 0 ? [0, 0] : searchpos('{', 'cW', last[0], 0, skip)
  var close = open == [0, 0] ? [0, 0] : searchpairpos('{', '', '}', 'W', skip, last[0])
  if close == [0, 0]
    SelectIndentedBody(target, last, skip)
    return
  endif
  var open_c = [open[0], charcol([open[0], open[1]]) + 1]
  var close_c = [close[0], charcol([close[0], close[1]])]
  if strpart(getline(open[0]), open[1]) =~ '^\s*$'
    open_c = [open[0] + 1, FirstNonBlank(bufnr(), open[0] + 1)]
  endif
  if strpart(getline(close[0]), 0, close[1] - 1) =~ '^\s*$'
    if close[0] - 1 < open_c[0]
      return
    endif
    SelectRange(open_c, [close[0] - 1, max([strcharlen(getline(close[0] - 1)), 1])])
  else
    # Same-line body: without the padding inside the braces ("{ a+b }").
    var line = getline(open[0])
    while open_c[1] < close_c[1] && line->strcharpart(open_c[1] - 1, 1) =~ '\s'
      open_c[1] += 1
    endwhile
    var last_c = close_c[1] - 1
    while last_c > open_c[1] && getline(close[0])->strcharpart(last_c - 1, 1) =~ '\s'
      last_c -= 1
    endwhile
    if Before(open_c, close_c)
      SelectRange(open_c, [close_c[0], last_c])
    endif
  endif
enddef

const BRACELESS = ['python', 'lua']

# The lines after the header (name plus a parenthesised parameter list),
# without a closing "end", from the first non-blank character.
def SelectIndentedBody(target: dict<any>, last: list<number>, skip: string)
  setcursorcharpos(target.name_end[0], target.name_end[1])
  var header_end = target.name_end[0]
  if getline('.')[charcol('.') - 1 :] =~ '^\s*('
    search('(', 'cW')
    header_end = searchpairpos('(', '', ')', 'W', skip, last[0])[0] ?? header_end
  endif
  var first = header_end + 1
  var final = last[0]
  if getline(final) =~ '^\s*end\>' && final > target.start[0]
    final -= 1
  endif
  if first <= final
    SelectRange([first, FirstNonBlank(bufnr(), first)], [final, max([strcharlen(getline(final)), 1])])
  endif
enddef

for [lhs, kinds, inner] in [['am', 'FUNCTION_KINDS', false], ['im', 'FUNCTION_KINDS', true],
                            ['ac', 'ClassKinds()', false], ['ic', 'ClassKinds()', true]]
  execute $'xnoremap {lhs} <ScriptCmd>Select({kinds}, {inner})<CR>'
  execute $'onoremap {lhs} <ScriptCmd>Select({kinds}, {inner})<CR>'
endfor

# --- Motions -------------------------------------------------------------------

# Move to the [count]th next/previous start/end of a symbol of "kinds"; falls
# back to the builtin "key" without a documentSymbol server (or in diff mode
# for ]c/[c).
def Goto(kinds: list<number>, forward: bool, to_end: bool, key: string)
  var symbols = &diff && key =~ 'c$' ? [] : Symbols()
  if symbols->empty()
    execute $'normal! {v:count1}{key}'
    return
  endif
  var cur = Cursor()
  var positions = symbols->copy()
    ->filter((_, s) => kinds->index(s.kind) >= 0)
    ->map((_, s) => to_end ? LastChar(s.end) : s.start)
    ->sort((a, b) => a[0] - b[0] ?? a[1] - b[1])
  if forward
    positions->filter((_, p) => Before(cur, p))
  else
    positions->filter((_, p) => Before(p, cur))->reverse()
  endif
  if positions->empty()
    return
  endif
  var target = positions[min([v:count1, len(positions)]) - 1]
  normal! m'
  setcursorcharpos(target[0], target[1])
enddef

# ;/, always repeat forward/backward (repeat_last_move_next/_previous),
# including f/F/t/T and the moves registered through Repeatable().
var last_move: dict<any> = {}

def Repeatable(Move: func, forward: bool)
  last_move = {Move: Move, forward: forward}
  Move(forward)
enddef

def RepeatLastMove(forward: bool)
  last_move.Move(forward)
enddef

def RepeatKey(forward: bool): string
  if last_move->has_key('Move')
    return $"\<Cmd>call {expand('<SID>')}RepeatLastMove(v:{forward})\<CR>"
  endif
  var builtin_forward = last_move->get('key', 'f') =~# '[ft]'
  return forward == builtin_forward ? ';' : ','
enddef

def BuiltinMove(key: string): string
  last_move = {key: key}
  return key
enddef

for [lhs, kinds, to_end] in [[']c', 'ClassKinds()', false], ['[c', 'ClassKinds()', false],
                             [']m', 'FUNCTION_KINDS', false], ['[m', 'FUNCTION_KINDS', false],
                             [']M', 'FUNCTION_KINDS', true], ['[M', 'FUNCTION_KINDS', true]]
  var keys = $'fwd ? "]{lhs[1]}" : "[{lhs[1]}"'
  for md in ['n', 'x', 'o']
    execute $'{md}noremap {lhs} <ScriptCmd>Repeatable((fwd) => Goto({kinds}, fwd, {to_end}, {keys}), {lhs[0] == ']'})<CR>'
  endfor
endfor

for md in ['n', 'x', 'o']
  for key in ['f', 'F', 't', 'T']
    execute $'{md}noremap <expr> {key} BuiltinMove("{key}")'
  endfor
  execute $'{md}noremap <expr> ; RepeatKey(true)'
  execute $'{md}noremap <expr> , RepeatKey(false)'
endfor

# vim-gitgutter's hunk jumps join the same ;/, repeat.
def HunkMove(forward: bool)
  execute $"normal {v:count1}\<Plug>(GitGutter{forward ? 'Next' : 'Prev'}Hunk)"
enddef
nnoremap ]h <ScriptCmd>Repeatable(HunkMove, true)<CR>
nnoremap [h <ScriptCmd>Repeatable(HunkMove, false)<CR>
