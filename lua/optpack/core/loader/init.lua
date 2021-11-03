local OnEvents = require("optpack.core.loader.event").OnEvents
local OnFileTypes = require("optpack.core.loader.filetype").OnFileTypes
local OnCommands = require("optpack.core.loader.cmd").OnCommands
local OnModules = require("optpack.core.loader.module").OnModules

local M = {}

local Loader = {}
Loader.__index = Loader
M.Loader = Loader

function Loader.new(plugin, load_on, pre_load_hook, post_load_hook)
  vim.validate({
    plugin = {plugin, "table"},
    load_on = {load_on, "table"},
    pre_load_hook = {pre_load_hook, "function"},
    post_load_hook = {post_load_hook, "function"},
  })

  local plugin_name = plugin.name
  local group_name = "optpack_" .. plugin_name
  vim.cmd(([[
augroup %s
  autocmd!
augroup END
]]):format(group_name))

  OnEvents.set(plugin_name, group_name, load_on.events)
  OnFileTypes.set(plugin_name, group_name, load_on.filetypes)
  OnCommands.set(plugin_name, group_name, load_on.cmds)
  local autocmd_remover = function()
    vim.cmd("autocmd! " .. group_name)
  end
  local lua_loader_removers = OnModules.set(plugin_name, load_on.modules)

  local tbl = {
    _plugin = plugin,
    _pre_load_hook = pre_load_hook,
    _post_load_hook = post_load_hook,
    _removers = {autocmd_remover, unpack(lua_loader_removers)},
  }
  return setmetatable(tbl, Loader)
end

function Loader.load(self)
  for _, remover in ipairs(self._removers) do
    remover()
  end

  local plugin = self._plugin:expose()
  self._pre_load_hook(plugin)
  vim.cmd("packadd " .. self._plugin.name)
  self._post_load_hook(plugin)
end

return M
