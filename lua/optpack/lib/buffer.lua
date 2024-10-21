local M = {}

--- @param bufnr integer
--- @param name string
function M.set_name_by_force(bufnr, name)
  local old = vim.fn.bufnr(("^%s$"):format(name))
  if old ~= -1 then
    vim.api.nvim_buf_delete(old, { force = true })
  end
  vim.api.nvim_buf_set_name(bufnr, name)
end

local OutputFollower = {}
OutputFollower.__index = OutputFollower
M.OutputFollower = OutputFollower

function OutputFollower.new(bufnr)
  local windows = vim
    .iter(vim.fn.win_findbuf(bufnr))
    :map(function(window_id)
      local pos = vim.api.nvim_win_get_cursor(window_id)
      return { id = window_id, row = pos[1], column = pos[2] }
    end)
    :totable()

  local last_row = vim.api.nvim_buf_line_count(bufnr)
  local tbl = {
    _windows = vim
      .iter(windows)
      :filter(function(e)
        return e.row == last_row
      end)
      :totable(),
    _bufnr = bufnr,
  }
  return setmetatable(tbl, OutputFollower)
end

function OutputFollower.follow(self)
  local last_row = vim.api.nvim_buf_line_count(self._bufnr)
  for _, window in ipairs(self._windows) do
    vim.api.nvim_win_set_cursor(window.id, { last_row, window.column })
  end
end

return M
