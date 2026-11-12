vim9script
# Port of config/nvim/after/lsp/jdtls.lua (nvim-jdtls).

import './lsp.vim'

# One runtime per major version of the mise-installed JDKs; the active one is
# the default. Broken installs (no bin/java) are skipped.
def JavaRuntimes(): list<dict<any>>
  var out = system('mise ls --json --installed java')
  if v:shell_error != 0
    return []
  endif
  var runtimes: list<dict<any>> = []
  var seen: dict<dict<any>> = {}
  for install in json_decode(out)
    var major = install.version->matchstr('\d\+')
    if major->empty() || !executable($'{install.install_path}/bin/java')
      continue
    endif
    var name = $'JavaSE-{major}'
    if !seen->has_key(name)
      seen[name] = {name: name, path: install.install_path}
      runtimes->add(seen[name])
    endif
    if install->get('active', false)
      seen[name].path = install.install_path
      seen[name].default = true
    endif
  endfor
  return runtimes
enddef

# Like the nested root_markers in after/lsp/jdtls.lua: prefer the
# multi-module markers, fall back to the single-module ones.
def JdtlsRootMarkers(): list<string>
  const groups = [
    ['mvnw', 'gradlew', 'settings.gradle', 'settings.gradle.kts', '.git/'],
    ['build.xml', 'pom.xml', 'build.gradle', 'build.gradle.kts'],
  ]
  var dir = expand('%:p:h')
  for m in groups[0]
    if !(m =~ '/$' ? finddir(m[: -2], $'{dir};') : findfile(m, $'{dir};'))->empty()
      return groups[0]
    endif
  endfor
  return groups[1]
enddef

# The jdtls instance serving buffer "bnr", if any.
def JdtlsOf(bnr: number): dict<any>
  if bnr < 1
    return {}
  endif
  return lsp#buffer#BufLspServersGet(bnr)
    ->copy()->filter((_, s) => !s->empty() && s.name == 'jdtls')->get(0, {})
enddef

def CurJdtls(): dict<any>
  return JdtlsOf(bufnr())
enddef

def ApplyEdit(edit: any)
  if type(edit) == v:t_dict
    lsp#textedit#ApplyWorkspaceEdit(edit)
  endif
enddef

# Like ui.pick_one of nvim-jdtls: returns the index of the chosen item or -1.
def PickOne(labels: list<string>, prompt: string): number
  var choice = inputlist([prompt] + labels->mapnew((i, l) => $'{i + 1}: {l}'))
  redraw
  return choice >= 1 && choice <= labels->len() ? choice - 1 : -1
enddef

# Like ui.pick_many of nvim-jdtls: type a number (or a range "2-4") to toggle
# items, an empty answer finishes. Returns the indexes of the selected items.
def PickMany(labels: list<string>, prompt: string, selected: list<bool> = []): list<number>
  var sel = selected->empty() ? labels->mapnew((_, _) => false) : selected->copy()
  while true
    var lines = labels->mapnew((i, l) => $'{i + 1}. {l}{sel[i] ? " *" : ""}')
    var answer = input($"\n{lines->join("\n")}\n{prompt} (Esc to finish): ")
    if answer->empty()
      break
    endif
    var m = answer->matchlist('^\s*\(\d\+\)\s*\%(-\s*\(\d*\)\)\=\s*$')
    if m->empty()
      continue
    endif
    var first = max([1, str2nr(m[1])])
    var last = m[0] =~ '-' ? (m[2]->empty() ? labels->len() : min([labels->len(), str2nr(m[2])])) : first
    for i in range(min([first, last]), max([first, last]))
      if i <= labels->len()
        sel[i - 1] = !sel[i - 1]
      endif
    endfor
  endwhile
  redraw
  return range(labels->len())->filter((i, _) => sel[i])
enddef

# Send "method" to "server" and call Cb() with the result. Prompting from the
# channel callback leaves Vim at a hit-enter prompt, so Cb() runs from a timer.
def Request(server: dict<any>, method: string, params: dict<any>, Cb: func(any))
  server.rpc_a(method, params, (_, result, _) => timer_start(0, (_) => Cb(result)))
enddef

# Send "method" to "server" and apply the workspace edit it returns.
def RequestEdit(server: dict<any>, method: string, params: dict<any>)
  server.rpc_a(method, params, (_, edit, _) => ApplyEdit(edit))
enddef

def FieldLabel(f: dict<any>): string
  return $'{f.name}: {f.type}'
enddef

def MethodLabel(m: dict<any>): string
  return $'{m.name}({m.parameters->join(", ")})'
enddef

# The client-side commands of nvim-jdtls (jdtls.commands); "cmd.arguments[0]"
# are the textDocument/codeAction params.

# Without a selection, yegappan/lsp asks for the code actions from the cursor
# to the end of the line, and jdtls then inserts the generated code at the
# cursor; nvim sends the cursor position, so jdtls appends it to the class.
def CodeActionParams(cmd: dict<any>): dict<any>
  var params = cmd.arguments[0]->deepcopy()
  if params.range.start.line == params.range.end.line
    params.range.end = params.range.start
  endif
  return params
enddef

def OrganizeImportsCmd(_: dict<any>)
  OrganizeImports()
enddef

# <leader>co, like jdtls.organize_imports(): ambiguous types are resolved by
# the server asking for java.action.organizeImports.chooseImports.
def OrganizeImports()
  var server = CurJdtls()
  if server->empty()
    return
  endif
  var pos = server.getTextDocPosition(false)
  RequestEdit(server, 'java/organizeImports', {textDocument: pos.textDocument,
    range: {start: pos.position, end: pos.position}, context: {diagnostics: []}})
enddef

# :JdtUpdateConfig, like jdtls.update_project_config(): reload the build
# configuration (pom.xml, build.gradle) of the project of the current buffer.
def UpdateProjectConfig()
  var server = CurJdtls()
  if server->empty()
    return
  endif
  server.sendNotification('java/projectConfigurationUpdate', {uri: lsp#util#LspBufnrToUri(bufnr())})
enddef

# Server request; params.arguments: [uri, ImportSelection[], restoreExisting]. Returns the
# chosen ImportCandidate of each selection.
def ChooseImports(args: list<any>): list<any>
  var [uri, selections] = args[: 1]
  var bnr = lsp#util#LspUriToBufnr(uri)
  if bnr != bufnr()
    execute $'buffer {bnr}'
  endif
  var choices = []
  for selection in selections
    var start = selection.range.start
    cursor(start.line + 1, start.character + 1)
    normal! zvzz
    var id = matchaddpos('IncSearch', [[start.line + 1, start.character + 1,
      selection.range['end'].character - start.character]])
    redraw
    var candidates = selection.candidates
    var fqn: string = candidates[0].fullyQualifiedName
    var idx = candidates->len() == 1 ? 0 : PickOne(candidates->mapnew((_, c) => c.fullyQualifiedName),
      $'Choose type {fqn->matchstr('[^.]*$')} to import')
    matchdelete(id)
    choices->add(idx < 0 ? v:null : candidates[idx])
  endfor
  return choices
enddef

def GenerateConstructors(cmd: dict<any>)
  var server = CurJdtls()
  var params = CodeActionParams(cmd)
  Request(server, 'java/checkConstructorsStatus', params, (status) => {
    if type(status) != v:t_dict || status->get('constructors', [])->empty()
      return
    endif
    var constructors = status.constructors
    if constructors->len() > 1
      constructors = PickMany(constructors->mapnew((_, c) => MethodLabel(c)),
        'Include super class constructor(s): ')->mapnew((_, i) => constructors[i])
      if constructors->empty()
        return
      endif
    endif
    var fields = status->get('fields', [])
    if !fields->empty()
      fields = PickMany(fields->mapnew((_, f) => FieldLabel(f)), 'Include field to initialize by constructor(s): ',
        fields->mapnew((_, f) => f->get('isSelected', false)))->mapnew((_, i) => fields[i])
    endif
    RequestEdit(server, 'java/generateConstructors', {context: params, constructors: constructors, fields: fields})
  })
enddef

def OverrideMethods(cmd: dict<any>)
  var server = CurJdtls()
  var params = CodeActionParams(cmd)
  Request(server, 'java/listOverridableMethods', params, (result) => {
    if type(result) != v:t_dict || result->get('methods', [])->empty()
      echo 'No methods to override'
      return
    endif
    var methods = result.methods
    var selected = PickMany(methods->mapnew((_, m) => $'{MethodLabel(m)} class: {m.declaringClass}'),
      'Method to override')->mapnew((_, i) => methods[i])
    if !selected->empty()
      RequestEdit(server, 'java/addOverridableMethods', {context: params, overridableMethods: selected})
    endif
  })
enddef

# toString() and hashCode()/equals(): check, pick the fields, generate.
def GenerateFromFields(check: string, generate: string, prompt: string, cmd: dict<any>)
  var server = CurJdtls()
  var params = CodeActionParams(cmd)
  Request(server, check, params, (result) => {
    if type(result) != v:t_dict || result->get('fields', [])->empty()
      return
    endif
    if result->get('exists', false) && PickOne(['Replace', 'Cancel'],
        $"Method 'toString()' already exists in '{result.type}'. Do you want to replace it?") != 0
      return
    endif
    var fields = result.fields
    RequestEdit(server, generate, {context: params,
      fields: PickMany(fields->mapnew((_, f) => FieldLabel(f)), prompt)->mapnew((_, i) => fields[i])})
  })
enddef

const commands = {
  'java.apply.workspaceEdit': (cmd) => cmd.arguments->foreach((_, e) => ApplyEdit(e)),
  'java.action.organizeImports': OrganizeImportsCmd,
  'java.action.generateConstructorsPrompt': GenerateConstructors,
  'java.action.overrideMethodsPrompt': OverrideMethods,
  'java.action.generateToStringPrompt': function(GenerateFromFields,
    ['java/checkToStringStatus', 'java/generateToString', 'Include item in toString?']),
  'java.action.hashCodeEqualsPrompt': function(GenerateFromFields,
    ['java/checkHashCodeEqualsStatus', 'java/generateHashCodeEquals', 'Include item in equals/hashCode?']),
}

# jdtls asks the client to run commands with workspace/executeClientCommand.
def ExecuteClientCommand(server: dict<any>, req: dict<any>)
  var command = req.params.command
  if command == 'java.action.organizeImports.chooseImports'
    # Like Request(), prompt from a timer.
    timer_start(0, (_) => server.sendResponse(req, ChooseImports(req.params.arguments), {}))
  else
    server.sendResponse(req, v:null, {code: -32601, message: $'Command {command} not supported on client'})
  endif
enddef

# What the commands above handle, from nvim-jdtls' extendedClientCapabilities.
const extendedClientCapabilities = {
  classFileContentsSupport: true,
  advancedOrganizeImportsSupport: true,
  generateConstructorsPromptSupport: true,
  overrideMethodsPromptSupport: true,
  generateToStringPromptSupport: true,
  hashCodeEqualsPromptSupport: true,
  executeClientCommandSupport: true,
}

def AddJdtls()
  # Started through sh below, so ignoreMissingServer can't skip it.
  if !executable('jdtls')
    return
  endif
  var runtimes = JavaRuntimes()
  # jdtls itself needs a newer JDK than projects may use (current snapshots
  # require Java 25), so launch it with the newest installed runtime.
  var newest = runtimes->copy()->sort((a, b) => str2nr(b.name->matchstr('\d\+$')) - str2nr(a.name->matchstr('\d\+$')))
  var java = newest->empty() ? [] : ['--java-executable', $'{newest[0].path}/bin/java']
  g:LspAddServer([lsp.Primary({
    name: 'jdtls', filetype: ['java'],
    # Like nvim, one workspace data dir per root, named after it. Each root
    # gets its own instance (serverPerRoot) started in that root, so the name
    # is taken from the working directory of the server.
    path: 'sh',
    args: ['-c', 'd=$1; shift; exec jdtls -data "$d/${PWD##*/}" "$@"', 'jdtls',
      $'{$XDG_CACHE_HOME ?? expand("~/.cache")}/vim/jdtls/workspace',
      # lombok.jar is installed by packages/install/packages/85-lsp-java.sh.
      $'--jvm-arg=-javaagent:{expand('~/usr/local/jdtls/lombok.jar')}',
      '--jvm-arg=-XX:+UseParallelGC',
      '--jvm-arg=-XX:GCTimeRatio=4',
      '--jvm-arg=-XX:AdaptiveSizePolicyWeight=90',
      '--jvm-arg=-Xmx6G',
      '--jvm-arg=-Xms1G'] + java,
    rootSearch: JdtlsRootMarkers(),
    initializationOptions: {extendedClientCapabilities: extendedClientCapabilities},
    customRequestHandlers: {'workspace/executeClientCommand': ExecuteClientCommand},
    workspaceConfig: {java: {configuration: {runtimes: runtimes}}},
  })])
enddef

# Like jdtls.open_classfile(): fill a jdt:// buffer (a class of the JDK or of
# a dependency) with the source jdtls returns, and attach that jdtls to it.
def ReadClassFile(uri: string)
  var bnr = bufnr()
  setlocal buftype=nofile noswapfile modifiable
  var server = JdtlsOf(bufnr('#'))
  if server->empty()
    server = getbufinfo({bufloaded: true})->mapnew((_, b) => JdtlsOf(b.bufnr))
      ->filter((_, s) => !s->empty())->get(0, {})
  endif
  if server->empty()
    echohl ErrorMsg | echomsg $'No jdtls to load {uri}' | echohl None
    return
  endif
  # nvim-jdtls waits up to 5s (jdt_uri_timeout_ms).
  var text = server.rpc('java/classFileContents', {uri: uri}, {timeout: 5000})->get('result', '')
  silent :%delete _
  setline(1, (type(text) == v:t_string ? text : '')->split('\r\=\n', true))
  setlocal nomodifiable nomodified filetype=java
  lsp#lsp#AttachServers(bnr, [server])
enddef

# Vim refuses tag entries that are URLs ('tagsecure', E1576), so <C-]> on a
# symbol of the JDK or of a dependency (a jdt:// location) goes through
# :LspGotoDefinition, which also pushes to the tag stack.
def TagJump()
  var tagstack = gettagstack()
  try
    execute $"normal! {v:count > 0 ? v:count : ''}\<C-]>"
  catch /E1576:/
    # Drop the entry of the failed jump; :LspGotoDefinition pushes its own.
    settagstack(winnr(), tagstack, 'r')
    LspGotoDefinition
  endtry
enddef

if executable('jdtls')
  for [name, Handler] in commands->items()
    g:LspRegisterCmdHandler(name, Handler)
  endfor
endif

augroup kzx_jdtls
  autocmd!
  autocmd FileType java ++once AddJdtls()
  autocmd FileType java nnoremap <buffer> <leader>co <ScriptCmd>OrganizeImports()<CR>
  autocmd FileType java nnoremap <buffer> <C-]> <ScriptCmd>TagJump()<CR>
  autocmd FileType java command! -buffer JdtUpdateConfig UpdateProjectConfig()
  autocmd BufReadCmd jdt://* ReadClassFile(expand('<amatch>'))
augroup END
