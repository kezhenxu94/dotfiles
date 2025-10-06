local function get_mason_bundles()
  local function jars(path, pattern)
    return vim.split(vim.fn.glob(vim.fn.expand(path) .. "/" .. pattern), "\n")
  end

  local bundles = {}
  vim.list_extend(bundles, jars("$MASON/share/java-test", "*.jar"))
  vim.list_extend(bundles, jars("$MASON/share/java-debug-adapter", "com.microsoft.java.debug.plugin-*.jar"))
  vim.list_extend(bundles, jars("$MASON/share/vscode-spring-boot-tools", "jdtls/*.jar"))

  local excluded = {}

  bundles = vim.tbl_filter(function(bundle)
    if not bundle then
      return false
    end
    local filename = vim.fn.fnamemodify(bundle, ":t")
    for _, ex in ipairs(excluded) do
      if filename == ex then
        return false
      end
    end
    return true
  end, bundles)

  return bundles
end

---@type vim.lsp.Config
return {
  on_attach = function(_, bufnr)
    local jdtls = require("jdtls")
    jdtls.setup_dap({
      config_overrides = {
        console = "internalConsole",
      },
    })
    vim.keymap.set("n", "<leader>tm", jdtls.test_nearest_method, {
      buffer = bufnr,
      desc = "Debug Test Method",
    })
    vim.keymap.set("n", "<leader>tt", jdtls.test_class, {
      buffer = bufnr,
      desc = "Debug Test Class",
    })
  end,
  dap = {
    config_overrides = {
      console = "internalConsole",
    },
  },
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
      format = {
        enabled = true,
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
  jdtls = {
    -- handlers = {
    -- ["language/status"] = function(_, _) end,
    -- },
  },
  init_options = {
    bundles = get_mason_bundles(),
  },
}
