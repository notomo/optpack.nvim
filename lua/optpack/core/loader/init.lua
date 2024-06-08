local OnEvents = require("optpack.core.loader.event")
local OnFileTypes = require("optpack.core.loader.filetype")
local OnCommands = require("optpack.core.loader.cmd")
local OnModules = require("optpack.core.loader.module")
local OnKeymaps = require("optpack.core.loader.keymap")

--- @class OptpackLoader
local Loader = {}
Loader.__index = Loader

function Loader.new(plugin, load_on, pre_load_hook, post_load_hook)
  vim.validate({
    plugin = { plugin, "table" },
    load_on = { load_on, "table" },
    pre_load_hook = { pre_load_hook, "callable" },
    post_load_hook = { post_load_hook, "callable" },
  })

  local plugin_name = plugin.name

  local keymap_remover = OnKeymaps.set(plugin_name, load_on.keymaps)
  if type(keymap_remover) == "string" then
    local err = keymap_remover
    return err
  end

  local group_name = "optpack_" .. plugin_name
  vim.api.nvim_create_augroup(group_name, {})

  OnEvents.set(plugin_name, group_name, load_on.events)
  OnFileTypes.set(plugin_name, group_name, load_on.filetypes)
  OnCommands.set(plugin_name, group_name, load_on.cmds)
  local autocmd_remover = function()
    vim.api.nvim_clear_autocmds({ group = group_name })
  end

  local lua_loader_removers = OnModules.set(plugin_name, load_on.modules)

  local tbl = {
    _plugin = plugin,
    _pre_load_hook = pre_load_hook,
    _post_load_hook = post_load_hook,
    _removers = { autocmd_remover, keymap_remover, unpack(lua_loader_removers) },
  }
  return setmetatable(tbl, Loader)
end

function Loader.load(self)
  for _, remover in ipairs(self._removers) do
    remover()
  end

  local plugin = self._plugin:expose()

  do
    local ok, err = pcall(self._pre_load_hook, plugin)
    if not ok then
      return ("%s: pre_load: %s"):format(plugin.name, err)
    end
  end

  vim.cmd.packadd(self._plugin.name)

  local errs = {}
  do
    local ok, err = pcall(self._post_load_hook, plugin)
    if not ok then
      table.insert(errs, ("%s: post_load: %s"):format(plugin.name, err))
    end
  end

  do
    local err = self:_validate_after_loading()
    if err then
      table.insert(errs, err)
    end
  end

  if #errs ~= 0 then
    return table.concat(errs, "\n")
  end
end

function Loader._validate_after_loading(self)
  local paths = vim
    .iter(vim.api.nvim_list_runtime_paths())
    :map(function(path)
      return vim.fs.normalize(path)
    end)
    :totable()

  if not vim.tbl_contains(paths, self._plugin.directory) then
    return ([[failed to load expected directory: %s]]):format(self._plugin.directory)
  end

  for _, path in ipairs(paths) do
    local name = vim.fs.basename(path)
    if self._plugin.name == name and self._plugin.directory ~= path then
      return ([[loaded, but the same and prior plugin exists in 'runtimepath': %s]]):format(path)
    end
    if self._plugin.name == name and self._plugin.directory == path then
      return nil
    end
  end
end

return Loader
