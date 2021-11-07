local Once = require("optpack.lib.once").Once
local bufferlib = require("optpack.lib.buffer")

local M = {}
M.__index = M

function M.new(cmd_type, message_factory, opts)
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].filetype = "optpack"
  vim.bo[bufnr].modifiable = false
  bufferlib.set_name_by_force(bufnr, "optpack://optpack-" .. cmd_type)
  opts.open(bufnr)
  local tbl = {
    _bufnr = bufnr,
    _ns = vim.api.nvim_create_namespace("optpack"),
    _delete_first_line = Once.new(function()
      vim.api.nvim_buf_set_lines(bufnr, 0, 1, false, {})
    end),
    _message_factory = message_factory,
  }
  return setmetatable(tbl, M), nil
end

function M.handle(self, event_name, ctx, ...)
  if not vim.api.nvim_buf_is_valid(self._bufnr) then
    return
  end

  local lines, hl_group = self._message_factory:create(event_name, ...)
  if not lines then
    return
  end

  lines = vim.tbl_map(function(line)
    return self:_format(ctx, line)
  end, lines)

  vim.bo[self._bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(self._bufnr, -1, -1, false, lines)
  self._delete_first_line()
  vim.bo[self._bufnr].modifiable = false

  if not hl_group then
    return
  end

  local count = vim.api.nvim_buf_line_count(self._bufnr)
  vim.api.nvim_buf_set_extmark(self._bufnr, self._ns, count - #lines, 0, {
    end_line = count,
    hl_group = hl_group,
  })
end

function M._format(_, ctx, line)
  if not ctx.name then
    return ("> %s"):format(line)
  end
  return ("%s > %s"):format(ctx.name, line)
end

return M
