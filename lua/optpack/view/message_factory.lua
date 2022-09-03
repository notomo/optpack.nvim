local Event = require("optpack.core.event").Event
local HighlightedLines = require("optpack.lib.highlighted_lines")

local M = {}

local MessageFactory = {}
MessageFactory.__index = MessageFactory
M.MessageFactory = MessageFactory

MessageFactory.default_handlers = {
  [Event.StartInstall] = function(self, ctx)
    return { { self:_prefix(ctx), { "Start installing." } } }
  end,
  [Event.Installed] = function(self, ctx)
    return { { self:_prefix(ctx), { "Installed." } } }
  end,
  [Event.FinishedInstall] = function(self, ctx)
    return { { self:_prefix(ctx), { "Finished installing." } } }
  end,

  [Event.StartUpdate] = function(self, ctx)
    return { { self:_prefix(ctx), { "Start updating." } } }
  end,
  [Event.Updated] = function(self, ctx, revision_range)
    return { { self:_prefix(ctx), { "Updated. " }, { revision_range, "OptpackUpdatedRevisionRange" } } }
  end,
  [Event.GitCommitLog] = function(self, ctx, outputs)
    local prefix = self:_prefix(ctx)
    return vim.tbl_map(function(commit)
      return { prefix, { commit.revision, "OptpackGitCommitRevision" }, { commit.message, "OptpackGitCommitLog" } }
    end, outputs)
  end,
  [Event.FinishedUpdate] = function(self, ctx)
    return { { self:_prefix(ctx), { "Finished updating." } } }
  end,

  [Event.Progressed] = function()
    return {}
  end,

  [Event.Error] = function(self, ctx, err)
    local prefix = self:_prefix(ctx)
    if type(err) == "table" then
      return vim.tbl_map(function(e)
        return { prefix, { e, "OptpackError" } }
      end, err)
    end
    return { { prefix, { err, "OptpackError" } } }
  end,
}

function MessageFactory.new(handlers)
  vim.validate({ handlers = { handlers, "table" } })
  local tbl = { _handlers = vim.tbl_extend("force", MessageFactory.default_handlers, handlers) }
  return setmetatable(tbl, MessageFactory)
end

function MessageFactory.create(self, event_name, ctx, ...)
  local handler = self._handlers[event_name]
  if not handler or type(handler) ~= "function" then
    return nil
  end
  local normal, info = handler(self, ctx, ...)
  if normal then
    return HighlightedLines.new(normal)
  end
  if info then
    return nil, info
  end
  return nil
end

function MessageFactory._prefix(_, ctx)
  if not ctx.name then
    return { "> " }
  end
  return { ("%s > "):format(ctx.name) }
end

local highlightlib = require("optpack.lib.highlight")
local force = false
M.hl_groups = {
  highlightlib.link("OptpackGitCommitLog", force, "Comment"),
  highlightlib.link("OptpackGitCommitRevision", force, "Comment"),
  highlightlib.link("OptpackUpdatedRevisionRange", force, "Comment"),
  highlightlib.link("OptpackProgressed", force, "Comment"),
  highlightlib.link("OptpackError", force, "WarningMsg"),
}

return M
