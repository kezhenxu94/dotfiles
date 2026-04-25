vim.pack.add({ "https://github.com/mason-org/mason.nvim" }, { confirm = false })

require("mason").setup({})

local async = require("mason-core.async")
local registry = require("mason-registry")

-- stylua: ignore start
local packages = vim
  .iter(require("config.languages"))
  :map(function(srv) return srv.mason end)
  :filter(function(x) return x end)
  :flatten()
  :totable()
-- stylua: ignore end

local function install_wanted()
  for _, name in ipairs(packages) do
    local ok, pkg = pcall(registry.get_package, name)
    if not ok or not pkg then
      vim.api.nvim_echo({ { "Mason: package not found - " .. name } }, false, {})
    else
      if not pkg:is_installed() then
        vim.api.nvim_echo({ { "Installing " .. name } }, false, {})
        pkg:install()
      else
        local installed_version = pkg:get_installed_version() or ""
        local latest_version = pkg:get_latest_version()
        if latest_version and installed_version ~= latest_version then
          vim.api.nvim_echo({ { string.format("New version available: %s (%s → %s)", name, installed_version, latest_version) } }, false, {})
        end
      end
    end
  end
end

local function uninstall_unwanted()
  for _, name in ipairs(registry.get_installed_package_names()) do
    if not vim.tbl_contains(packages, name) then
      local pkg = registry.get_package(name)
      async.run(function()
        vim.api.nvim_echo({ { "Uninstalling " .. name } }, false, {})
        async.wait(function(resolve)
          pkg:uninstall(nil, resolve)
        end)
      end)
    end
  end
end

registry.refresh(function()
  install_wanted()
  uninstall_unwanted()
end)
