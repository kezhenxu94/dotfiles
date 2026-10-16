---@type vim.lsp.Config
return {
  cmd = { 'docker-language-server', 'start', '--stdio' },
  filetypes = { 'dockerfile', 'yaml.docker-compose', 'hcl.docker-bake' },
  get_language_id = function(_, ftype)
    if ftype:lower():find('ya?ml') then
      return 'dockercompose'
    elseif ftype == 'hcl.docker-bake' then
      return 'dockerbake'
    else
      return ftype
    end
  end,
  root_markers = {
    'Dockerfile',
    'docker-compose.yaml',
    'docker-compose.yml',
    'compose.yaml',
    'compose.yml',
    'docker-bake.json',
    'docker-bake.hcl',
    'docker-bake.override.json',
    'docker-bake.override.hcl',
  },
}
