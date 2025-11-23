vim.pack.add({ "https://github.com/mfussenegger/nvim-jdtls" }, { confirm = false, load = true })

local function get_mason_bundles()
  local function jars(path, pattern)
    return vim.split(vim.fn.glob(vim.fn.expand(path) .. "/" .. pattern), "\n")
  end

  local bundles = {}
  vim.list_extend(bundles, jars("$MASON/packages/java-debug-adapter/extension/server", "*.jar"))
  vim.list_extend(bundles, jars("$MASON/packages/java-test/extension/server", "*.jar"))
  vim.list_extend(bundles, jars("$MASON/packages/jdtls", "*.jar"))
  return bundles
end

---@type vim.lsp.Config
return {
  on_attach = function(_, bufnr)
    local jdtls = require("jdtls")
    local opts = {
      config_overrides = {
        console = "internalConsole",
      },
    }
    vim.keymap.set("n", "<leader>tm", function()
      jdtls.test_nearest_method(opts)
    end, {
      buffer = bufnr,
      desc = "Debug Test Method",
    })
    vim.keymap.set("n", "<leader>tt", function()
      jdtls.test_class(opts)
    end, {
      buffer = bufnr,
      desc = "Debug Test Class",
    })
    vim.keymap.set("n", "<leader>co", function()
      jdtls.organize_imports()
    end, {
      buffer = bufnr,
      desc = "Organize Imports",
    })
    vim.keymap.set("n", "<leader>gS", function()
      require("jdtls.tests").goto_subjects()
    end, {
      buffer = bufnr,
      desc = "Go to Test Subject",
    })
  end,
  settings = {
    java = {
      configuration = {
        runtimes = {
          {
            name = "JavaSE-17",
            path = vim.fn.expand("~/.local/share/mise/installs/java/17/"),
          },
          {
            name = "JavaSE-21",
            path = vim.fn.expand("~/.local/share/mise/installs/java/21/"),
          },
        },
      },
    },
  },
  init_options = {
    bundles = get_mason_bundles(),
    workspace = {
      didChangeWatchedFiles = {
        dynamicRegistration = true,
      },
      refresh = {
        enabled = true,
      },
    },
    extendedClientCapabilities = require("jdtls").extendedClientCapabilities,
  },
}
