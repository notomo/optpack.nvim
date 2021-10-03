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

function Loaders.set(full_name, load_on)
  vim.validate({full_name = {full_name, "string"}, load_on = {load_on, "table"}})

  local splitted = vim.split(full_name, "/", true)
  local plugin_name = splitted[#splitted]

  OnEvents.set(plugin_name, load_on.events)
  OnFileTypes.set(plugin_name, load_on.filetypes)
  OnCommands.set(plugin_name, load_on.cmds)
  OnModules.set(plugin_name, load_on.modules)
end

return M
