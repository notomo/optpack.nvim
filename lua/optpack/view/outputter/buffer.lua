local Event = require("optpack.core.event").Event
local MessageFactory = require("optpack.view.message_factory").MessageFactory
local message_converter = require("optpack.view.message_converter")
local Once = require("optpack.lib.once")
local bufferlib = require("optpack.lib.buffer")
local vim = vim

local M = {}
M.__index = M

function M.new(cmd_type, opts)
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].filetype = "optpack"
  vim.bo[bufnr].modifiable = false
  vim.b[bufnr].optpack_updates = {}
  bufferlib.set_name_by_force(bufnr, "optpack://optpack-" .. cmd_type)
  opts.open(bufnr)
  local tbl = {
    _bufnr = bufnr,
    _delete_first_line = Once.new(function()
      vim.api.nvim_buf_set_lines(bufnr, 0, 1, false, {})
    end),
    _message_factory = MessageFactory.new(M.handlers),
    _progress_ns = vim.api.nvim_create_namespace("optpack-progress"),
    _progress_lines = {},
    _decorator = require("optpack.vendor.misclib.decorator").factory("optpack", bufnr):create(),
  }
  return setmetatable(tbl, M), nil
end

M.handlers = {
  [Event.Progressed] = function(_, _, finished_count, all_count)
    local digit = #tostring(all_count)
    local fmt = ("[ %%%dd / %%%dd ]"):format(digit, digit)
    local progress = { { { (fmt):format(finished_count, all_count), "OptpackProgressed" } } }
    return nil, { progress = progress }
  end,
}

function M.handle(self, event_name, ctx, ...)
  if not vim.api.nvim_buf_is_valid(self._bufnr) then
    return
  end

  local messages, info = self._message_factory:create(event_name, ctx, ...)
  if not (messages or info) then
    return
  end

  local output_follower = bufferlib.OutputFollower.new(self._bufnr)

  if messages then
    vim.bo[self._bufnr].modifiable = true
    local lines = message_converter.to_lines(messages)
    vim.api.nvim_buf_set_lines(self._bufnr, -1, -1, false, lines)
    self._delete_first_line()
    vim.bo[self._bufnr].modifiable = false

    local end_row = vim.api.nvim_buf_line_count(self._bufnr)
    message_converter.highlight(self._decorator, messages, end_row - #messages)
    self:_redraw_progress(end_row)
  end
  if info and info.progress then
    self._progress_lines = info.progress
    local end_row = vim.api.nvim_buf_line_count(self._bufnr)
    self:_redraw_progress(end_row)
  end
  if info and info.update then
    local updates = vim.b[self._bufnr].optpack_updates
    local window_id = vim.fn.win_findbuf(self._bufnr)[1]
    if window_id then
      local row = vim.api.nvim_win_get_cursor(window_id)[1] + 1
      updates[tostring(row)] = info.update
      vim.b[self._bufnr].optpack_updates = updates
    end
  end

  output_follower:follow()
end

function M._redraw_progress(self, end_row)
  vim.api.nvim_buf_clear_namespace(self._bufnr, self._progress_ns, 0, -1)
  vim.api.nvim_buf_set_extmark(self._bufnr, self._progress_ns, end_row - 1, 0, {
    virt_lines = self._progress_lines,
  })
end

return M
