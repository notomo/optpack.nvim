local Once = require("optpack.lib.once").Once
local bufferlib = require("optpack.lib.buffer")
local vim = vim

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

  local hl_lines = self._message_factory:create(event_name, ctx, ...)
  if not hl_lines then
    return
  end

  local output_follower = bufferlib.OutputFollower.new(self._bufnr)

  vim.bo[self._bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(self._bufnr, -1, -1, false, hl_lines:lines())
  self._delete_first_line()
  vim.bo[self._bufnr].modifiable = false

  local end_row = vim.api.nvim_buf_line_count(self._bufnr)
  hl_lines:add_highlight(self._bufnr, self._ns, end_row)

  output_follower:follow(end_row)
end

return M
