vim.pack.add({ "https://github.com/mfussenegger/nvim-jdtls" }, { confirm = false, load = true })

-- java-debug-adapter and java-test jars are installed (from their VS Code
-- extensions) by packages/install/packages/85-lsp-java.sh.
local function get_bundles()
  local function jars(glob)
    return vim.split(vim.fn.glob(glob), "\n", { trimempty = true })
  end

  local bundles = {}
  vim.list_extend(bundles, jars("~/usr/local/jdtls/java-debug-adapter/*.jar"))
  vim.list_extend(bundles, jars("~/usr/local/jdtls/java-test/*.jar"))
  return bundles
end

-- One runtime per major version from mise-installed JDKs; the mise-active
-- install wins and becomes the default, otherwise the first listed wins.
-- Broken installs (no bin/java) are skipped.
local function get_runtimes()
  local res = vim.system({ "mise", "ls", "--json", "--installed", "java" }, { text = true }):wait()
  if res.code ~= 0 then
    return {}
  end

  local runtimes, seen = {}, {}
  for _, install in ipairs(vim.json.decode(res.stdout)) do
    local major = install.version:match("(%d+)")
    local name = major and "JavaSE-" .. major
    if name and vim.fn.executable(install.install_path .. "/bin/java") == 1 then
      local runtime = seen[name]
      if not runtime then
        runtime = { name = name, path = install.install_path }
        seen[name] = runtime
        table.insert(runtimes, runtime)
      end
      if install.active then
        runtime.path = install.install_path
        runtime.default = true
      end
    end
  end
  return runtimes
end

-- Lives in after/ so it overrides the lsp/jdtls.lua bundled with nvim-jdtls.
---@type vim.lsp.Config
return {
  cmd = function(dispatchers, config)
    local data_dir = vim.fn.stdpath("cache") .. "/jdtls/workspace"
    if config.root_dir then
      data_dir = data_dir .. "/" .. vim.fn.fnamemodify(config.root_dir, ":p:h:t")
    end

    local cmd = {
      "jdtls",
      "-data",
      data_dir,
      -- lombok.jar is installed by packages/install/packages/85-lsp-java.sh.
      "--jvm-arg=-javaagent:" .. vim.fn.expand("~/usr/local/jdtls/lombok.jar"),
      "--jvm-arg=-XX:+UseParallelGC",
      "--jvm-arg=-XX:GCTimeRatio=4",
      "--jvm-arg=-XX:AdaptiveSizePolicyWeight=90",
      "--jvm-arg=-Xmx6G",
      "--jvm-arg=-Xms1G",
    }

    return vim.lsp.rpc.start(cmd, dispatchers, {
      cwd = config.cmd_cwd,
      env = config.cmd_env,
      detached = config.detached,
    })
  end,
  root_markers = {
    -- Multi-module projects; .git is the last resort for multi-module Maven projects
    { "mvnw", "gradlew", "settings.gradle", "settings.gradle.kts", ".git" },
    -- Single-module projects
    { "build.xml", "pom.xml", "build.gradle", "build.gradle.kts" },
  },
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
        runtimes = get_runtimes(),
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
