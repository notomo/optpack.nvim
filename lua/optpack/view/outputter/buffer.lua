local M = {}

function M.init()
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].filetype = "optpack"
  vim.cmd("botright split")
  vim.cmd("buffer " .. bufnr)
  return {bufnr = bufnr, ns = vim.api.nvim_create_namespace("optpack")}, nil
end

local handlers = {
  ["clone"] = function(lines)
    return lines
  end,
  ["pull"] = function(lines)
    return lines
  end,
  ["start"] = function()
    return {"Start."}
  end,
  ["installed"] = function()
    return {"Installed."}
  end,
  ["updated"] = function()
    return {"Updated."}
  end,
  ["finished"] = function()
    return {"Finished."}
  end,
  ["error"] = function(msg)
    if type(msg) == "table" then
      return msg
    end
    return {msg}
  end,
}

function M._format(_, ctx, line)
  if not ctx.name then
    return ("> %s"):format(line)
  end
  if not ctx.speaker then
    return ("%s > %s"):format(ctx.name, line)
  end
  return ("%s (%s) > %s"):format(ctx.name, ctx.speaker, line)
end

function M.info(self, event_name, ctx, ...)
  if not vim.api.nvim_buf_is_valid(self.bufnr) then
    return
  end
  local handler = handlers[event_name]
  if not handler then
    return
  end
  local lines = vim.tbl_map(function(line)
    return self:_format(ctx, line)
  end, handler(...))
  vim.api.nvim_buf_set_lines(self.bufnr, -1, -1, false, lines)
  return true
end

function M.error(self, event_name, ctx, ...)
  local ok = self:info(event_name, ctx, ...)
  if not ok then
    return
  end
  local count = vim.api.nvim_buf_line_count(self.bufnr)
  vim.api.nvim_buf_set_extmark(self.bufnr, self.ns, count - 1, 0, {
    end_line = count,
    hl_group = "WarningMsg",
  })
end

return M
