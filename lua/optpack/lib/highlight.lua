local vim = vim

local M = {}

function M.link(name, force, to)
  if force then
    vim.cmd(("highlight! link %s %s"):format(name, to))
  else
    vim.cmd(("highlight default link %s %s"):format(name, to))
  end
  return name
end

return M
