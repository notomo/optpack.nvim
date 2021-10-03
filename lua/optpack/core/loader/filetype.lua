local OnEvents = require("optpack.core.loader.event").OnEvents

local M = {}

local OnFileTypes = {}
OnFileTypes.__index = OnFileTypes
M.OnFileTypes = OnFileTypes

function OnFileTypes.set(plugin_name, group_name, filetypes)
  local events = vim.tbl_map(function(filetype)
    return {"FileType", filetype}
  end, filetypes)
  OnEvents.set(plugin_name, group_name, events)
end

return M
