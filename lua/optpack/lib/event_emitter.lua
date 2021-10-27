local M = {}

local EventEmitters = {}
EventEmitters.__index = EventEmitters
M.EventEmitters = EventEmitters

function EventEmitters.new(emitters, ctx)
  vim.validate({emitters = {emitters, "table"}, ctx = {ctx, "table", true}})
  local tbl = {_emitters = emitters, _ctx = ctx or {}}
  return setmetatable(tbl, EventEmitters)
end

function EventEmitters.emit(self, event_name, ...)
  for _, emitter in ipairs(self._emitters) do
    emitter:emit(event_name, self._ctx, ...)
  end
end

function EventEmitters.with(self, ctx)
  ctx = vim.tbl_extend("force", self._ctx, ctx)
  return EventEmitters.new(self._emitters, ctx)
end

return M
