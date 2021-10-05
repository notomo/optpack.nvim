local M = {}

function M.init()
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].filetype = "optpack"
  vim.cmd("botright split")
  vim.cmd("buffer " .. bufnr)
  return {bufnr = bufnr}, nil
end

function M.info(self, ctx, msg)
  local prefix = ("[%s] "):format(ctx.name)
  vim.api.nvim_buf_set_lines(self.bufnr, -1, -1, false, {prefix .. msg})
end

function M.error(self, ctx, msg)
  local prefix = ("[%s] "):format(ctx.name)
  vim.api.nvim_buf_set_lines(self.bufnr, -1, -1, false, {prefix .. msg})
  -- TODO: highlight
end

return M
