local Event = require("optpack.core.event").Event

local M = {}

local MessageFactory = {}
MessageFactory.__index = MessageFactory
M.MessageFactory = MessageFactory

-- TODO: change to [[msg, hl], ...]
MessageFactory.default_handlers = {
  [Event.StartInstall] = function()
    return {"Start installing."}
  end,
  [Event.GitCloned] = function(output)
    return output
  end,
  [Event.Installed] = function()
    return {"Installed."}
  end,
  [Event.FinishedInstall] = function()
    return {"Finished installing."}
  end,

  [Event.StartUpdate] = function()
    return {"Start updating."}
  end,
  [Event.GitPulled] = function(_)
    return {}
  end,
  [Event.Updated] = function(revision_range)
    local msg = ("Updated. (%s)"):format(revision_range)
    return {msg}
  end,
  [Event.GitCommitLog] = function(output)
    return output, "Comment"
  end,
  [Event.FinishedUpdate] = function()
    return {"Finished updating."}
  end,

  [Event.Error] = function(err)
    if type(err) == "table" then
      return err
    end
    return {err}, "WarningMsg"
  end,
}

function MessageFactory.new(handlers)
  vim.validate({handlers = {handlers, "table"}})
  local tbl = {_handlers = vim.tbl_extend("force", MessageFactory.default_handlers, handlers)}
  return setmetatable(tbl, MessageFactory)
end

function MessageFactory.create(self, event_name, ...)
  local handler = self._handlers[event_name]
  if not handler or type(handler) ~= "function" then
    return nil
  end
  return handler(...)
end

return M
