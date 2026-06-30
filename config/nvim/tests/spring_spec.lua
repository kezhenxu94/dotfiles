-- Headless unit tests for config.lsp.spring.
--
-- Run with:
--   nvim --headless --noplugin -u NONE \
--     --cmd "set rtp+=config/nvim" \
--     -l config/nvim/tests/spring_spec.lua
--
-- (or simply: nvim --headless -l config/nvim/tests/spring_spec.lua  when the
-- module is already on the runtimepath)
--
-- Requires the `java` tree-sitter parser to be installed and loadable.

-- Make the module discoverable when invoked with a bare `-l` from the repo root.
local here = debug.getinfo(1, "S").source:sub(2)
local nvim_root = vim.fn.fnamemodify(here, ":h:h") -- .../config/nvim
vim.opt.runtimepath:prepend(nvim_root)

local spring = require("config.lsp.spring")
local I = spring._internal

local failures = 0
local passed = 0

local function eq(actual, expected, msg)
  if actual ~= expected then
    failures = failures + 1
    print(
      string.format("  FAIL: %s\n    expected: %s\n    actual:   %s", msg, vim.inspect(expected), vim.inspect(actual))
    )
  else
    passed = passed + 1
  end
end

local function ok(cond, msg)
  if not cond then
    failures = failures + 1
    print("  FAIL: " .. msg)
  else
    passed = passed + 1
  end
end

----------------------------------------------------------------------
print("== path join / normalization ==")
----------------------------------------------------------------------
eq(I.join("/users", "/core"), "/users/core", "slash + slash")
eq(I.join("/users/", "/core"), "/users/core", "trailing + leading slash")
eq(I.join("/users", "core"), "/users/core", "no leading slash on sub")
eq(I.join("/users", ""), "/users", "empty sub")
eq(I.join("", "/core"), "/core", "empty base")
eq(I.join("", ""), "/", "both empty -> root")
eq(I.join("users/", "/core/"), "/users/core", "trailing on both")
eq(I.join("/a/b", "/c/d"), "/a/b/c/d", "multi-segment")

----------------------------------------------------------------------
print("== parse_string: prompt example ==")
----------------------------------------------------------------------
local function index_by_path(records)
  local m = {}
  for _, r in ipairs(records) do
    m[r.path] = r
  end
  return m
end

local java_ok = pcall(vim.treesitter.language.add, "java")
if not java_ok then
  print("  SKIP: java tree-sitter parser not available; skipping parser tests")
else
  local src = [[
@RestController
@RequestMapping("/users")
public class UserController {
    @GetMapping("/core")
    public User core() {}
    @GetMapping("/ordinary")
    public User ordinary() {}
}
]]
  local recs = I.parse_string(src)
  local m = index_by_path(recs)
  ok(m["/users/core"] ~= nil, "/users/core indexed")
  ok(m["/users/ordinary"] ~= nil, "/users/ordinary indexed")
  if m["/users/core"] then
    eq(m["/users/core"].method, "core", "method name")
    eq(m["/users/core"].class, "UserController", "class name")
    eq(m["/users/core"].http_method, "GET", "http method")
  end

  print("== parse_string: path= and value= named args ==")
  local src2 = [[
@Controller
@RequestMapping(path="/api")
public class A {
    @PostMapping(value="/save")
    public void save() {}
}
]]
  local m2 = index_by_path(I.parse_string(src2))
  ok(m2["/api/save"] ~= nil, "named path= + value= composed")
  if m2["/api/save"] then
    eq(m2["/api/save"].http_method, "POST", "POST verb")
  end

  print("== parse_string: empty method path ==")
  local src3 = [[
@RestController
@RequestMapping("/users")
public class B {
    @GetMapping
    public User all() {}
}
]]
  local m3 = index_by_path(I.parse_string(src3))
  ok(m3["/users"] ~= nil, "marker mapping -> class base path")

  print("== parse_string: array of paths ==")
  local src4 = [[
@RestController
public class C {
    @RequestMapping({"/a","/b"})
    public void multi() {}
}
]]
  local m4 = index_by_path(I.parse_string(src4))
  ok(m4["/a"] ~= nil and m4["/b"] ~= nil, "array yields one endpoint per path")

  print("== parse_string: non-controller class skipped ==")
  local src5 = [[
@Service
public class NotAController {
    @GetMapping("/x")
    public void x() {}
}
]]
  eq(#I.parse_string(src5), 0, "no @Controller/@RestController -> no endpoints")

  print("== parse_string: missing leading slash normalized ==")
  local src6 = [[
@RestController
@RequestMapping("users")
public class D {
    @GetMapping("core")
    public void core() {}
}
]]
  local m6 = index_by_path(I.parse_string(src6))
  ok(m6["/users/core"] ~= nil, "missing leading slashes normalized")

  print("== parse_string: non-literal path skipped ==")
  local src7 = [[
@RestController
public class E {
    @GetMapping(Endpoints.FOO)
    public void foo() {}
}
]]
  -- No string literal -> path resolves to "/" only via empty; ensure it does
  -- not crash and does not produce a bogus literal path.
  local recs7 = I.parse_string(src7)
  ok(recs7["/Endpoints.FOO"] == nil, "non-literal constant not treated as path")

  print("== parse_string: no class-level mapping ==")
  local src8 = [[
@RestController
public class F {
    @GetMapping("/ping")
    public void ping() {}
}
]]
  local m8 = index_by_path(I.parse_string(src8))
  ok(m8["/ping"] ~= nil, "method path stands alone without class base")

  ----------------------------------------------------------------------
  print("== match_entries resolution (find) ==")
  ----------------------------------------------------------------------
  -- Build a small index by hand.
  I.index.paths = {}
  I.insert_endpoints("/proj/UserController.java", I.parse_string([[
@RestController
@RequestMapping("/users")
public class UserController {
    @GetMapping("/core")
    public User core() {}
    @GetMapping("/comments")
    public User comments() {}
}
]]))

  -- match_entries returns endpoint records (path/file/line/class/method/...).
  local exact = I.match_entries("/users/core")
  eq(#exact, 1, "exact match returns one record")
  if exact[1] then
    eq(exact[1].path, "/users/core", "record path")
    eq(exact[1].http_method, "GET", "record http method")
    eq(exact[1].class, "UserController", "record class")
    ok(exact[1].file:match("UserController%.java$") ~= nil, "record file set")
    ok(type(exact[1].line) == "number", "record line is a number")
  end

  local prefix = I.match_entries("/users/co")
  ok(#prefix == 2, "prefix /users/co matches core and comments")

  local none = I.match_entries("/nope")
  eq(#none, 0, "no match returns empty")
end

----------------------------------------------------------------------
print(string.format("\n%d passed, %d failed", passed, failures))
if failures > 0 then
  os.exit(1)
end
