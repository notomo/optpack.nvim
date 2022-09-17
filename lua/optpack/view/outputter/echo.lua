local MessageFactory = require("optpack.view.message_factory").MessageFactory
local messagelib = require("optpack.vendor.misclib.message")

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
  local normal = self._message_factory:create(event_name, ctx, ...)
  if not normal then
    return
  end

  for _, line in normal:iter() do
    vim.api.nvim_echo({ { messagelib.wrap("") }, unpack(line:all()) }, true, {})
  end
end

return M
