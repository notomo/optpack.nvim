local Event = require("optpack.core.event").Event
local Once = require("optpack.lib.once").Once
local bufferlib = require("optpack.lib.buffer")

local M = {}
M.__index = M

function M.new(cmd_type, opts)
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
  }
  return setmetatable(tbl, M), nil
end

local handlers = {
  [Event.StartInstall] = function()
    return {"Start installing."}
  end,
  [Event.GitCloned] = function(output)
    return output
  end,
  [Event.Installed] = function()
    return {"Installed."}
  end,
  [Event.FinishedInstall] = function()
    return {"Finished installing."}
  end,

  [Event.StartUpdate] = function()
    return {"Start updating."}
  end,
  [Event.GitPulled] = function(_)
    return {}
  end,
  [Event.Updated] = function(reivision_diff)
    local msg = ("Updated. (%s)"):format(reivision_diff)
    return {msg}
  end,
  [Event.GitCommitLog] = function(output)
    return output, "Comment"
  end,
  [Event.FinishedUpdate] = function()
    return {"Finished updating."}
  end,

  [Event.Error] = function(err)
    if type(err) == "table" then
      return err
    end
    return {err}, "WarningMsg"
  end,
}

function M.emit(self, event_name, ctx, ...)
  if not vim.api.nvim_buf_is_valid(self._bufnr) then
    return
  end

  local handler = handlers[event_name]
  if not handler then
    return
  end

  local lines, hl_group = handler(...)
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
