local MessageFactory = require("optpack.view.message_factory").MessageFactory

local M = {}
M.__index = M

function M.new()
  local is_headless = vim.tbl_contains(vim.v.argv, "--headless")
  local tbl = {
    _message_factory = MessageFactory.new(M.handlers),
    _suffix = is_headless and "\n" or "",
  }
  return setmetatable(tbl, M), nil
end

M.handlers = {}

function M.handle(self, event_name, ctx, ...)
  local messages = self._message_factory:create(event_name, ctx, ...)
  if not messages then
    return
  end

  for _, chunks in ipairs(messages) do
    local msg = { { "[optpack] " }, unpack(chunks) }
    table.insert(msg, { self._suffix })
    vim.api.nvim_echo(msg, true, {})
  end
end

return M
