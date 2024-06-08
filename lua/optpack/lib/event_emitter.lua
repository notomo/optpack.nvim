--- @class OptpackEventEmitter
local EventEmitter = {}
EventEmitter.__index = EventEmitter

function EventEmitter.new(handlers, ctx)
  vim.validate({ handlers = { handlers, "table" }, ctx = { ctx, "table", true } })
  local tbl = { _handlers = handlers, _ctx = ctx or {} }
  return setmetatable(tbl, EventEmitter)
end

function EventEmitter.emit(self, event_name, ...)
  vim.validate({ event_name = { event_name, "string" } })
  for _, handler in ipairs(self._handlers) do
    handler:handle(event_name, self._ctx, ...)
  end
end

function EventEmitter.with(self, ctx)
  ctx = vim.tbl_extend("force", self._ctx, ctx)
  return EventEmitter.new(self._handlers, ctx)
end

return EventEmitter
