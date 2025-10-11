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

local root_markers = {
  -- Multi-module projects
  "mvnw",
  "gradlew",
  "build.gradle",
  "build.gradle.kts",
  ".git",
  -- Single-module projects
  "pom.xml", -- Maven
  "settings.gradle", -- Gradle
  "settings.gradle.kts", -- Gradle
}

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
  end,
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
  root_markers = root_markers,
}
