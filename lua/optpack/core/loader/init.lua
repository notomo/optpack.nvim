local OnEvents = require("optpack.core.loader.event").OnEvents
local OnFileTypes = require("optpack.core.loader.filetype").OnFileTypes
local OnCommands = require("optpack.core.loader.cmd").OnCommands
local OnModules = require("optpack.core.loader.module").OnModules

local M = {}

local Loaders = {}
Loaders.__index = Loaders
M.Loaders = Loaders

vim.cmd([[
augroup optpack
  autocmd!
augroup END
]])

function Loaders.set(pack, load_on)
  vim.validate({pack = {pack, "table"}, load_on = {load_on, "table"}})
  OnEvents.set(pack.plugin_name, load_on.events)
  OnFileTypes.set(pack.plugin_name, load_on.filetypes)
  OnCommands.set(pack.plugin_name, load_on.cmds)
  OnModules.set(pack, load_on.modules)
end

return M
