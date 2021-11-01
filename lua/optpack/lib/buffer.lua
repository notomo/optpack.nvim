local M = {}

function M.set_name_by_force(bufnr, name)
  vim.validate({bufnr = {bufnr, "number"}, name = {name, "string"}})
  local old = vim.fn.bufnr(("^%s$"):format(name))
  if old ~= -1 then
    vim.api.nvim_buf_delete(old, {force = true})
  end
  vim.api.nvim_buf_set_name(bufnr, name)
end

return M
