local OnEvents = require("optpack.core.loader.event")

local OnFileTypes = {}

function OnFileTypes.set(plugin_name, group_name, filetypes)
  local events = vim
    .iter(filetypes)
    :map(function(filetype)
      return { "FileType", filetype }
    end)
    :totable()
  OnEvents.set(plugin_name, group_name, events)
end

return OnFileTypes
