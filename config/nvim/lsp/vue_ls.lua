-- vue-component-meta's `typescript: "*"` peer makes npm nest the latest
-- TypeScript (7.x, native, no JS API), which crashes the server; use the
-- TypeScript bundled with vtsls instead.
local cmd = { 'vue-language-server', '--stdio' }
local npm_root = vim.fn.trim(vim.fn.system({ 'npm', 'root', '-g' }))
local tsdk = npm_root .. '/@vtsls/language-server/node_modules/typescript/lib'
if vim.v.shell_error == 0 and vim.uv.fs_stat(tsdk) then
  table.insert(cmd, '--tsdk=' .. tsdk)
end

---@type vim.lsp.Config
return {
  cmd = cmd,
  filetypes = { 'vue' },
  root_markers = { 'package.json' },
  on_init = function(client)
    local retries = 0

    ---@param _ lsp.ResponseError
    ---@param result any
    ---@param context lsp.HandlerContext
    local function typescriptHandler(_, result, context)
      local ts_client = vim.lsp.get_clients({ bufnr = context.bufnr, name = 'vtsls' })[1]

      if not ts_client then
        -- there can sometimes be a short delay until `vtsls` is attached so we retry for a few times until it is ready
        if retries <= 10 then
          retries = retries + 1
          vim.defer_fn(function()
            typescriptHandler(_, result, context)
          end, 100)
        else
          vim.notify('Could not find `vtsls` lsp client required by `vue_ls`.', vim.log.levels.ERROR)
        end
        return
      end

      local param = unpack(result)
      local id, command, payload = unpack(param)
      ts_client:exec_cmd({
        title = 'vue_request_forward', -- You can give title anything as it's used to represent a command in the UI, `:h Client:exec_cmd`
        command = 'typescript.tsserverRequest',
        arguments = {
          command,
          payload,
        },
      }, { bufnr = context.bufnr }, function(_, r)
        local response_data = { { id, r and r.body } }
        ---@diagnostic disable-next-line: param-type-mismatch
        client:notify('tsserver/response', response_data)
      end)
    end

    client.handlers['tsserver/request'] = typescriptHandler
  end,
}
