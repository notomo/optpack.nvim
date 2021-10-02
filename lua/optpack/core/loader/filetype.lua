local OnEvents = require("optpack.core.loader.event").OnEvents

local M = {}

local OnFileTypes = {}
OnFileTypes.__index = OnFileTypes
M.OnFileTypes = OnFileTypes

function OnFileTypes.set(plugin_name, filetypes)
  for _, filetype in ipairs(filetypes) do
    OnEvents.set_one(plugin_name, "FileType", filetype)
  end
end

return M
