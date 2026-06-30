vim.pack.add({ "https://github.com/mfussenegger/nvim-jdtls" }, { confirm = false, load = true })

-- java-debug-adapter and java-test jars are installed (from their VS Code
-- extensions) by packages/install/packages/84-lsp-bin.sh.
local function get_bundles()
  local function jars(glob)
    return vim.split(vim.fn.glob(vim.fn.expand(glob)), "\n", { trimempty = true })
  end

  local bundles = {}
  vim.list_extend(bundles, jars("~/usr/local/jdtls/java-debug-adapter/*.jar"))
  vim.list_extend(bundles, jars("~/usr/local/jdtls/java-test/*.jar"))
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
    bundles = get_bundles(),
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
