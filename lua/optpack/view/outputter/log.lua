local MessageFactory = require("optpack.view.message_factory").MessageFactory
local message_converter = require("optpack.view.message_converter")

local M = {}
M.__index = M

function M.new(_, opts)
  local dir = vim.fn.fnamemodify(opts.path, ":h")
  vim.fn.mkdir(dir, "p")
  local tbl = {
    _message_factory = MessageFactory.new(M.handlers),
    _path = opts.path,
  }
  return setmetatable(tbl, M), nil
end

M.handlers = {}

function M.handle(self, event_name, ctx, ...)
  local messages = self._message_factory:create(event_name, ctx, ...)
  if not messages then
    return
  end

  local lines = message_converter.to_lines(messages)
  if #lines == 0 then
    return
  end

  local f = io.open(self._path, "a")
  if not f then
    require("optpack.vendor.misclib.message").error("failed to open: " .. self._path)
    return
  end

  local time = os.date()
  for _, line in ipairs(lines) do
    f:write(("[%s] %s\n"):format(time, line))
  end
  f:close()
end

return M
