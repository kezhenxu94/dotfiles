-- Spring MVC endpoint navigation via Tree-sitter + Vim's native tag stack.
--
-- Indexes Spring controllers from Java source and exposes each endpoint's fully
-- resolved URL path (e.g. "/users/core") as a tag, so `:tjump /users/core`,
-- `<C-]>`, `:tselect`, `<C-t>`, `:pop` and `:tags` all behave like ctags --
-- without generating a tags file, running Spring, or invoking Maven/Gradle.
--
-- Enable: this module's setup() sets `tagfunc` buffer-local on Java buffers to
--   v:lua.require'config.lsp.spring'.tagfunc
--
-- Limitations (static source analysis only):
--   * Non-literal paths (@GetMapping(Endpoints.FOO), string concatenation) are
--     skipped -- the URL cannot be resolved without symbol resolution.
--   * Meta-annotations, custom @XxxMapping composed annotations, and paths
--     inherited from base controller classes are out of scope.
--   * The index reflects on-disk/saved state; unsaved buffer edits are picked up
--     on BufWritePost.

local M = {}

----------------------------------------------------------------------
-- Configuration
----------------------------------------------------------------------

local MAX_FILE_SIZE = 2 * 1024 * 1024 -- skip files larger than 2 MB
local BATCH_SIZE = 40 -- files parsed per event-loop tick during async build
local IGNORE_DIRS = { "/target/", "/build/", "/out/", "/bin/", "/.git/", "/node_modules/" }

-- Class-level annotations that mark a type as a web controller.
local CONTROLLER_ANNOTATIONS = {
  RestController = true,
  Controller = true,
}

-- Mapping annotation simple-name -> HTTP method. RequestMapping defaults to ANY
-- unless an explicit `method = RequestMethod.X` argument is present.
local MAPPING_HTTP_METHOD = {
  GetMapping = "GET",
  PostMapping = "POST",
  PutMapping = "PUT",
  DeleteMapping = "DELETE",
  PatchMapping = "PATCH",
  RequestMapping = "ANY",
}

----------------------------------------------------------------------
-- Path helpers
----------------------------------------------------------------------

-- Strip leading/trailing slashes from a single segment.
local function trim_slashes(s)
  return (s:gsub("^/+", ""):gsub("/+$", ""))
end

-- Compose a base path with a sub path, normalizing slashes.
--   join("/users", "/core")  -> "/users/core"
--   join("/users/", "/core") -> "/users/core"
--   join("/users", "core")   -> "/users/core"
--   join("/users", "")       -> "/users"
--   join("", "/core")        -> "/core"
--   join("", "")             -> "/"
local function join(base, sub)
  local segments = {}
  for _, part in ipairs({ base or "", sub or "" }) do
    part = trim_slashes(part)
    if part ~= "" then
      table.insert(segments, part)
    end
  end
  if #segments == 0 then
    return "/"
  end
  return "/" .. table.concat(segments, "/")
end

----------------------------------------------------------------------
-- Tree-sitter parsing
----------------------------------------------------------------------

-- Capture mapping/controller annotations together with the class and method
-- names. Relationships (which method belongs to which class) are resolved in
-- Lua by walking ancestors, which is more robust than a nested query when a
-- controller has no class-level @RequestMapping.
local QUERY_TEXT = [[
  (class_declaration
    (modifiers
      [(marker_annotation name: (_) @class.anno.name)
       (annotation name: (_) @class.anno.name
         arguments: (annotation_argument_list)? @class.anno.args)])
    name: (identifier) @class.name) @class.node

  (method_declaration
    (modifiers
      [(marker_annotation name: (_) @method.anno.name)
       (annotation name: (_) @method.anno.name
         arguments: (annotation_argument_list)? @method.anno.args)])
    name: (identifier) @method.name) @method.node
]]

local query_cache = nil
local java_available = nil

-- Lazily ensure the Java parser is loadable; cache the result.
local function ensure_java()
  if java_available == nil then
    java_available = pcall(vim.treesitter.language.add, "java")
  end
  return java_available
end

local function get_query()
  if not query_cache then
    query_cache = vim.treesitter.query.parse("java", QUERY_TEXT)
  end
  return query_cache
end

-- Annotation names may be plain `identifier` or a `scoped_identifier`
-- (e.g. @org.springframework.web.bind.annotation.GetMapping). Take the last
-- dotted component as the simple name.
local function simple_name(text)
  return text:match("[%w_]+$") or text
end

-- Collect all string-literal values found anywhere inside an
-- annotation_argument_list node. Handles the single-arg form
-- (@GetMapping("/x")), the named-arg form (path=/value="/x"), and the array
-- form ({"/a","/b"}) with the same scan.
--
-- For @RequestMapping(path=..., value=...) Spring treats `path` and `value` as
-- aliases, and we only care about path strings; keys like method/produces are
-- string-free for our purposes (method uses RequestMethod.X, a field_access).
local function collect_paths(args_node, src)
  local paths = {}
  if not args_node then
    return paths
  end
  -- Depth-first walk collecting string_literal -> string_fragment text.
  local function walk(node)
    if node:type() == "string_literal" then
      local fragments = {}
      for child in node:iter_children() do
        if child:type() == "string_fragment" then
          table.insert(fragments, vim.treesitter.get_node_text(child, src))
        end
      end
      -- Empty string ("") has no string_fragment child -> contributes "".
      table.insert(paths, table.concat(fragments))
      return
    end
    for child in node:iter_children() do
      walk(child)
    end
  end
  walk(args_node)
  return paths
end

-- Extract the HTTP verb from a @RequestMapping(method = RequestMethod.X) arg.
-- Returns nil if not present (caller falls back to the annotation default).
local function request_method_verb(args_node, src)
  if not args_node then
    return nil
  end
  for pair in args_node:iter_children() do
    if pair:type() == "element_value_pair" then
      local key = pair:field("key")[1]
      if key and vim.treesitter.get_node_text(key, src) == "method" then
        local value = pair:field("value")[1]
        if value then
          -- e.g. RequestMethod.POST -> POST
          return simple_name(vim.treesitter.get_node_text(value, src))
        end
      end
    end
  end
  return nil
end

-- Walk up from a node to the nearest enclosing class_declaration.
local function enclosing_class(node)
  local cur = node:parent()
  while cur do
    if cur:type() == "class_declaration" then
      return cur
    end
    cur = cur:parent()
  end
  return nil
end

-- Inspect a (modifiers ...) node for controller and mapping annotations.
-- Returns: is_controller (bool), base_paths (string[]), verb (string|nil).
local function scan_modifiers(class_node, src)
  local is_controller = false
  local base_paths = {}
  local verb = nil
  for child in class_node:iter_children() do
    if child:type() == "modifiers" then
      for anno in child:iter_children() do
        local t = anno:type()
        if t == "marker_annotation" or t == "annotation" then
          local name_node = anno:field("name")[1]
          if name_node then
            local name = simple_name(vim.treesitter.get_node_text(name_node, src))
            if CONTROLLER_ANNOTATIONS[name] then
              is_controller = true
            end
            if MAPPING_HTTP_METHOD[name] then
              local args = anno:field("arguments")[1]
              vim.list_extend(base_paths, collect_paths(args, src))
              if name == "RequestMapping" then
                verb = request_method_verb(args, src) or verb
              end
            end
          end
        end
      end
    end
  end
  return is_controller, base_paths, verb
end

-- Parse a string of Java source. Returns a list of endpoint records (without
-- the `file` field, which the caller fills in).
local function parse_string(src)
  if not ensure_java() then
    return {}
  end
  local ok, parser = pcall(vim.treesitter.get_string_parser, src, "java")
  if not ok or not parser then
    return {}
  end
  local tree = parser:parse()[1]
  if not tree then
    return {}
  end
  local root = tree:root()
  local query = get_query()

  -- First pass: gather class info keyed by the class_declaration node id.
  local classes = {} -- node:id() -> { name, base_paths, verb, is_controller }
  -- Second pass collects methods; we resolve their class on the fly.
  local endpoints = {}

  -- Cache class scan results so we don't re-scan per method.
  local function class_info(class_node)
    local id = class_node:id()
    local info = classes[id]
    if info == nil then
      local is_controller, base_paths, verb = scan_modifiers(class_node, src)
      info = { is_controller = is_controller, base_paths = base_paths, verb = verb }
      classes[id] = info
    end
    return info
  end

  for id, node in query:iter_captures(root, src, 0, -1) do
    local capture = query.captures[id]
    if capture == "method.node" then
      local method_node = node
      local class_node = enclosing_class(method_node)
      if class_node then
        local cinfo = class_info(class_node)
        if cinfo.is_controller then
          -- Find the method's mapping annotation(s).
          local name_node = method_node:field("name")[1]
          local method_name = name_node and vim.treesitter.get_node_text(name_node, src) or "?"
          for child in method_node:iter_children() do
            if child:type() == "modifiers" then
              for anno in child:iter_children() do
                local t = anno:type()
                if t == "marker_annotation" or t == "annotation" then
                  local anno_name_node = anno:field("name")[1]
                  local anno_name = anno_name_node
                      and simple_name(vim.treesitter.get_node_text(anno_name_node, src))
                    or ""
                  local default_verb = MAPPING_HTTP_METHOD[anno_name]
                  if default_verb then
                    local args = anno:field("arguments")[1]
                    local method_paths = collect_paths(args, src)
                    local verb = default_verb
                    if anno_name == "RequestMapping" then
                      verb = request_method_verb(args, src) or cinfo.verb or "ANY"
                    end
                    -- A mapping annotation with no path string still yields an
                    -- endpoint at the class base path.
                    if #method_paths == 0 then
                      method_paths = { "" }
                    end
                    local bases = #cinfo.base_paths > 0 and cinfo.base_paths or { "" }
                    local srow, scol = method_node:range()
                    -- Land on the method name line, not the annotation line.
                    local mrow = srow
                    if name_node then
                      mrow = ({ name_node:range() })[1]
                    end
                    local class_name = cinfo.name
                    if class_name == nil then
                      local cn = class_node:field("name")[1]
                      class_name = cn and vim.treesitter.get_node_text(cn, src) or "?"
                      cinfo.name = class_name
                    end
                    for _, base in ipairs(bases) do
                      for _, mpath in ipairs(method_paths) do
                        table.insert(endpoints, {
                          path = join(base, mpath),
                          line = mrow + 1,
                          column = scol + 1,
                          method = method_name,
                          class = class_name,
                          http_method = verb,
                        })
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  return endpoints
end

----------------------------------------------------------------------
-- Index
----------------------------------------------------------------------

local index = {
  paths = {}, -- path -> Endpoint[]
  mtimes = {}, -- file -> mtime (seconds) for cache invalidation
  built = false, -- a full build has completed at least once
  building = false, -- an async build is currently in flight
  generation = 0, -- bumped to cancel an in-flight build
}

local function should_ignore(file)
  for _, frag in ipairs(IGNORE_DIRS) do
    if file:find(frag, 1, true) then
      return true
    end
  end
  return false
end

local function project_root()
  return vim.fs.root(0, {
    ".git",
    "pom.xml",
    "build.gradle",
    "build.gradle.kts",
    "settings.gradle",
    "settings.gradle.kts",
  }) or vim.uv.cwd()
end

-- Read an entire file's bytes via libuv. Returns content or nil.
local function read_file(file)
  local fd = vim.uv.fs_open(file, "r", 438)
  if not fd then
    return nil
  end
  local stat = vim.uv.fs_fstat(fd)
  if not stat then
    vim.uv.fs_close(fd)
    return nil
  end
  if stat.size > MAX_FILE_SIZE then
    vim.uv.fs_close(fd)
    return nil, stat
  end
  local content = vim.uv.fs_read(fd, stat.size, 0)
  vim.uv.fs_close(fd)
  return content, stat
end

-- Remove all endpoint records that originate from `file`.
local function drop_file(file)
  for path, list in pairs(index.paths) do
    local kept = {}
    for _, ep in ipairs(list) do
      if ep.file ~= file then
        table.insert(kept, ep)
      end
    end
    if #kept == 0 then
      index.paths[path] = nil
    else
      index.paths[path] = kept
    end
  end
end

-- Insert endpoint records for a single file's parse result.
local function insert_endpoints(file, endpoints)
  for _, ep in ipairs(endpoints) do
    ep.file = file
    local list = index.paths[ep.path]
    if not list then
      list = {}
      index.paths[ep.path] = list
    end
    table.insert(list, ep)
  end
end

-- (Re)index a single file synchronously. Cheap enough for BufWritePost.
local function index_file(file, content_override)
  local content, stat = content_override, nil
  if content == nil then
    content, stat = read_file(file)
  else
    stat = vim.uv.fs_stat(file)
  end
  drop_file(file)
  if content == nil then
    index.mtimes[file] = nil
    return
  end
  insert_endpoints(file, parse_string(content))
  if stat then
    index.mtimes[file] = stat.mtime and stat.mtime.sec
  end
end

-- Drive the full project scan as a coroutine resumed in batches, yielding
-- between batches so the UI stays responsive. A `generation` token lets a new
-- build (e.g. :SpringEndpointRefresh) cancel an in-flight one.
local function build_async(on_done)
  if not ensure_java() then
    vim.notify("[spring] Java tree-sitter parser unavailable; endpoint index disabled", vim.log.levels.WARN)
    return
  end
  index.generation = index.generation + 1
  local my_gen = index.generation
  index.building = true

  local root = project_root()
  local files = vim.fs.find(function(name)
    return name:match("%.java$") ~= nil
  end, { path = root, type = "file", limit = math.huge })

  -- Build into fresh tables so partial lookups during a rebuild still see the
  -- previous complete index until we swap.
  local new_paths = {}
  local new_mtimes = {}

  local co = coroutine.create(function()
    local processed = 0
    for i, file in ipairs(files) do
      if not should_ignore(file) then
        local content, stat = read_file(file)
        if content then
          local endpoints = parse_string(content)
          for _, ep in ipairs(endpoints) do
            ep.file = file
            local list = new_paths[ep.path]
            if not list then
              list = {}
              new_paths[ep.path] = list
            end
            table.insert(list, ep)
          end
          if stat and stat.mtime then
            new_mtimes[file] = stat.mtime.sec
          end
        end
      end
      processed = processed + 1
      if processed % BATCH_SIZE == 0 then
        coroutine.yield()
      end
    end
  end)

  local function step()
    -- Abandon this build if a newer one superseded it.
    if my_gen ~= index.generation then
      return
    end
    local ok, err = coroutine.resume(co)
    if not ok then
      index.building = false
      vim.notify("[spring] index build error: " .. tostring(err), vim.log.levels.ERROR)
      return
    end
    if coroutine.status(co) == "dead" then
      -- Swap in the freshly built index.
      index.paths = new_paths
      index.mtimes = new_mtimes
      index.built = true
      index.building = false
      local count = 0
      for _, list in pairs(new_paths) do
        count = count + #list
      end
      vim.notify(string.format("[spring] indexed %d endpoints from %d files", count, #files))
      if on_done then
        on_done()
      end
    else
      vim.schedule(step)
    end
  end

  vim.schedule(step)
end

-- Ensure an index exists / is being built. Non-blocking.
local function ensure_index()
  if not index.built and not index.building then
    build_async()
  end
end

----------------------------------------------------------------------
-- Public API
----------------------------------------------------------------------

-- Force a full reindex.
function M.refresh()
  build_async()
end

-- Incrementally reindex a single file (used by BufWritePost).
function M.refresh_file(file, bufnr)
  if not file or file == "" then
    return
  end
  local content_override = nil
  if bufnr and vim.api.nvim_buf_is_loaded(bufnr) then
    content_override = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")
  end
  index_file(file, content_override)
end

-- Return a sorted list of all indexed endpoint paths.
function M.endpoints()
  local names = {}
  for path in pairs(index.paths) do
    table.insert(names, path)
  end
  table.sort(names)
  return names
end

-- Build the list of tag entries matching `pattern`, in the shape Vim's tagfunc
-- expects. Shared by jumps and command-line completion.
local function match_entries(pattern, flags)
  local results = {}
  local seen_order = {}

  local function emit(path)
    for _, ep in ipairs(index.paths[path] or {}) do
      table.insert(results, {
        name = ep.path,
        filename = ep.file,
        cmd = tostring(ep.line),
        kind = ep.http_method,
        user_data = ep.class .. "#" .. ep.method,
      })
    end
  end

  if flags:find("r") then
    -- :tag /re -- treat pattern as a regexp over endpoint paths.
    local ok, re = pcall(vim.regex, pattern)
    if ok then
      for _, path in ipairs(M.endpoints()) do
        if re:match_str(path) then
          emit(path)
        end
      end
    end
    return results
  end

  -- Exact match takes priority so `:tjump /users/core` jumps straight in.
  if index.paths[pattern] then
    emit(pattern)
    return results
  end

  -- Otherwise: prefix matches first, then remaining substring matches. This
  -- powers `:tjump /users/co<Tab>` completion and `:tselect`.
  local prefix, substr = {}, {}
  for _, path in ipairs(M.endpoints()) do
    local at = path:find(pattern, 1, true)
    if at == 1 then
      table.insert(prefix, path)
    elseif at then
      table.insert(substr, path)
    end
  end
  for _, path in ipairs(prefix) do
    emit(path)
  end
  for _, path in ipairs(substr) do
    emit(path)
  end
  return results
end

-- 'tagfunc' implementation. Resolver only -- it returns matches and lets Vim
-- perform the jump and manage the tag stack (so <C-t>/:pop/:tags all work).
function M.tagfunc(pattern, flags, _info)
  ensure_index()
  local ok, results = pcall(match_entries, pattern or "", flags or "")
  if not ok then
    return nil -- degrade gracefully; Vim falls back to default tag search
  end
  return results
end

-- Populate the location list with every endpoint and open it.
function M.list()
  ensure_index()
  local items = {}
  for _, path in ipairs(M.endpoints()) do
    for _, ep in ipairs(index.paths[path]) do
      table.insert(items, {
        filename = ep.file,
        lnum = ep.line,
        col = ep.column,
        text = string.format("%-40s %s#%s", ep.path, ep.class, ep.method),
      })
    end
  end
  table.sort(items, function(a, b)
    return a.text < b.text
  end)
  vim.fn.setloclist(0, {}, " ", { title = "Spring Endpoints", items = items })
  vim.cmd("lopen")
end

----------------------------------------------------------------------
-- Setup: commands, autocmds, buffer-local tagfunc
----------------------------------------------------------------------

function M.setup()
  local group = vim.api.nvim_create_augroup("kezhenxu94_spring_endpoint", { clear = true })

  -- Attach tagfunc to Java buffers only, leaving other filetypes untouched.
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "java",
    callback = function(args)
      vim.bo[args.buf].tagfunc = "v:lua.require'config.lsp.spring'.tagfunc"
    end,
  })

  -- Incremental reindex on save.
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    pattern = "*.java",
    callback = function(args)
      M.refresh_file(vim.api.nvim_buf_get_name(args.buf), args.buf)
    end,
  })

  vim.api.nvim_create_user_command("SpringEndpointRefresh", function()
    M.refresh()
  end, { desc = "Reindex Spring MVC endpoints" })

  vim.api.nvim_create_user_command("SpringEndpointList", function()
    M.list()
  end, { desc = "List Spring MVC endpoints in the location list" })

  -- Kick off the first build without blocking startup.
  vim.schedule(ensure_index)
end

-- Internals exposed for unit tests.
M._internal = {
  join = join,
  parse_string = parse_string,
  index = index,
  match_entries = match_entries,
  drop_file = drop_file,
  insert_endpoints = insert_endpoints,
}

return M
