local function get_mason_bundles()
  local function jars(path, pattern)
    return vim.split(vim.fn.glob(vim.fn.expand(path) .. "/" .. pattern), "\n")
  end

  local bundles = {}
  vim.list_extend(bundles, jars("$MASON/share/java-test", "*.jar"))
  vim.list_extend(bundles, jars("$MASON/share/java-debug-adapter", "com.microsoft.java.debug.plugin-*.jar"))
  vim.list_extend(bundles, jars("$MASON/share/vscode-spring-boot-tools", "jdtls/*.jar"))
  return bundles
end

---@type vim.lsp.Config
return {
  settings = {
    java = {
      configuration = {
        runtimes = {
          {
            name = "JavaSE-11",
            path = vim.fn.expand("~/.local/share/mise/installs/java/11/"),
          },
          {
            name = "JavaSE-17",
            path = vim.fn.expand("~/.local/share/mise/installs/java/17/"),
          },
          {
            name = "JavaSE-20",
            path = vim.fn.expand("~/.local/share/mise/installs/java/20/"),
          },
          {
            name = "JavaSE-21",
            path = vim.fn.expand("~/.local/share/mise/installs/java/21/"),
          },
        },
        updateBuildConfiguration = "automatic",
      },
      eclipse = {
        downloadSources = true,
      },
      maven = {
        downloadSources = true,
      },
      signatureHelp = {
        enabled = true,
      },
      contentProvider = {
        preferred = "fernflower",
      },
      sources = {
        organizeImports = {
          starThreshold = 9999,
          staticStarThreshold = 9999,
        },
      },
    },
  },
  init_options = {
    bundles = get_mason_bundles(),
    workspace = {
      refresh = {
        enabled = true,
      },
    },
    extendedClientCapabilities = require("jdtls").extendedClientCapabilities,
  },
}
