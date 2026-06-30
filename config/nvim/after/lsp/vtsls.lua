-- @see <https://github.com/vuejs/language-tools/wiki/Neovim>
-- @vue/language-server is installed globally via npm
-- (packages/install/packages/80-lsp-npm.sh); resolve the npm global root.
local function vue_language_server_path()
  local root = vim.fn.trim(vim.fn.system({ "npm", "root", "-g" }))
  if vim.v.shell_error ~= 0 or root == "" then
    return nil
  end
  local path = root .. "/@vue/language-server"
  return vim.uv.fs_stat(path) and path or nil
end

local tsserver_filetypes = {
  "typescript",
  "javascript",
  "javascriptreact",
  "typescriptreact",
  "vue",
}

local global_plugins = {}
local vue_path = vue_language_server_path()
if vue_path then
  table.insert(global_plugins, {
    name = "@vue/typescript-plugin",
    location = vue_path,
    languages = { "vue" },
    configNamespace = "typescript",
  })
end

return {
  settings = {
    vtsls = {
      tsserver = {
        globalPlugins = global_plugins,
      },
    },
  },
  filetypes = tsserver_filetypes,
}
