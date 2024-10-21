--- @class OptpackEventEmitter
--- @field private _ctx table
--- @field private _handlers table
local EventEmitter = {}
EventEmitter.__index = EventEmitter

--- @param handlers table
--- @param ctx table?
function EventEmitter.new(handlers, ctx)
  local tbl = { _handlers = handlers, _ctx = ctx or {} }
  return setmetatable(tbl, EventEmitter)
end

--- @param event_name string
function EventEmitter.emit(self, event_name, ...)
  for _, handler in ipairs(self._handlers) do
    handler:handle(event_name, self._ctx, ...)
  end
end

function EventEmitter.with(self, ctx)
  ctx = vim.tbl_extend("force", self._ctx, ctx)
  return EventEmitter.new(self._handlers, ctx)
end

return EventEmitter
