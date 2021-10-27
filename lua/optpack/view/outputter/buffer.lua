local Event = require("optpack.core.event").Event

local M = {}
M.__index = M

function M.new()
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].filetype = "optpack"
  vim.bo[bufnr].modifiable = false
  vim.cmd("botright split | buffer" .. bufnr)
  local tbl = {bufnr = bufnr, ns = vim.api.nvim_create_namespace("optpack")}
  return setmetatable(tbl, M), nil
end

local handlers = {
  [Event.StartInstall] = function()
    return {"Start."}
  end,
  [Event.GitCloned] = function(output)
    return output
  end,
  [Event.Installed] = function()
    return {"Installed."}
  end,
  [Event.FinishedInstall] = function()
    return {"Finished."}
  end,

  [Event.StartUpdate] = function()
    return {"Start."}
  end,
  [Event.GitPulled] = function(output)
    return output
  end,
  [Event.Updated] = function()
    return {"Updated."}
  end,
  [Event.FinishedUpdate] = function()
    return {"Finished."}
  end,

  [Event.Error] = function(err)
    if type(err) == "table" then
      return err
    end
    return {err}, "WarningMsg"
  end,
}

function M.emit(self, event_name, ctx, ...)
  if not vim.api.nvim_buf_is_valid(self.bufnr) then
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

  vim.bo[self.bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(self.bufnr, -1, -1, false, lines)
  vim.bo[self.bufnr].modifiable = false

  if not hl_group then
    return
  end

  local count = vim.api.nvim_buf_line_count(self.bufnr)
  vim.api.nvim_buf_set_extmark(self.bufnr, self.ns, count - 1, 0, {
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
