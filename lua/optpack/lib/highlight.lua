local vim = vim

local M = {}

function M.link(name, force, to)
  vim.api.nvim_set_hl(0, name, {
    link = to,
    default = not force,
  })
  return name
end

return M
