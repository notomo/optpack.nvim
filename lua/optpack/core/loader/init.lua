local OnEvents = require("optpack.core.loader.event").OnEvents
local OnFileTypes = require("optpack.core.loader.filetype").OnFileTypes
local OnCommands = require("optpack.core.loader.cmd").OnCommands
local OnModules = require("optpack.core.loader.module").OnModules

local M = {}

local Loaders = {}
Loaders.__index = Loaders
M.Loaders = Loaders

local LoaderRemovers = {}
LoaderRemovers.__index = LoaderRemovers
M.LoaderRemovers = LoaderRemovers

function Loaders.set(plugin, load_on)
  vim.validate({plugin = {plugin, "table"}, load_on = {load_on, "table"}})

  local group_name = "optpack_" .. plugin.name
  vim.cmd(([[
augroup %s
  autocmd!
augroup END
]]):format(group_name))

  OnEvents.set(plugin.name, group_name, load_on.events)
  OnFileTypes.set(plugin.name, group_name, load_on.filetypes)
  OnCommands.set(plugin.name, group_name, load_on.cmds)
  local autocmd_remover = function()
    vim.cmd("autocmd! " .. group_name)
  end
  local lua_loader_removers = OnModules.set(plugin, load_on.modules)
  return LoaderRemovers.new({autocmd_remover, unpack(lua_loader_removers)})
end

function LoaderRemovers.new(raw_removers)
  local tbl = {_removers = raw_removers}
  return setmetatable(tbl, LoaderRemovers)
end

function LoaderRemovers.execute(self)
  for _, remover in ipairs(self._removers) do
    remover()
  end
end

return M
