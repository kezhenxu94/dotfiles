vim.pack.add({
  { src = "https://github.com/mason-org/mason.nvim" },
}, { confirm = false, load = true })

require("mason").setup({})

local packages = vim
  .iter(require("config.languages"))
  :map(function(server)
    return server.mason
  end)
  :filter(function(server)
    return server
  end)
  :flatten()
  :totable()

vim.api.nvim_create_user_command("MasonSync", function()
  vim.notify("Syncing packages...", vim.log.levels.INFO)

  local async = require("mason-core.async")
  local registry = require("mason-registry")

  async.run(function()
    vim.notify("Updating registry...", vim.log.levels.INFO)
    async.wait(function(resolve)
      registry.update(resolve)
    end)

    for _, name in ipairs(packages) do
      local pkg = registry.get_package(name)
      if not pkg:is_installed() then
        async.scheduler()
        vim.notify("Installing " .. name, vim.log.levels.INFO)
        async.wait(function(resolve)
          pkg:install():once("closed", resolve)
        end)
      else
        local installed_version = pkg:get_installed_version() or ""
        local latest_version = pkg:get_latest_version()
        if latest_version and installed_version ~= latest_version then
          async.scheduler()
          vim.notify(
            "Updating " .. name .. " from " .. installed_version .. " to " .. latest_version,
            vim.log.levels.INFO
          )
          async.wait(function(resolve)
            pkg:install({ version = latest_version }, resolve)
          end)
        end
      end
    end

    for _, name in ipairs(registry.get_installed_package_names()) do
      local pkg = registry.get_package(name)
      if not vim.tbl_contains(packages, name) then
        async.scheduler()
        vim.notify("Uninstalling " .. name, vim.log.levels.INFO)
        async.wait(function(resolve)
          pkg:uninstall(nil, resolve)
        end)
      end
    end
  end, function()
    vim.notify("Succesfully synced " .. #packages .. " packages.", vim.log.levels.INFO)
  end)
end, { force = true })
