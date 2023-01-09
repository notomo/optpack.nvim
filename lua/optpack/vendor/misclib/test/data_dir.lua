local M = {}
M.__index = M

function M.setup(root_path, opts)
  opts = opts or {}
  local base_dir = opts.base_dir or "test_data/"
  local base_path = root_path .. "/" .. base_dir
  local relative_path = base_dir .. math.random(1, 2 ^ 30) .. "/"
  local full_path = root_path .. "/" .. relative_path
  local tbl = {
    relative_path = relative_path,
    full_path = full_path,
    _base_path = base_path,
  }
  local self = setmetatable(tbl, M)

  self:create_dir("")

  return self
end

function M.create_file(self, path, content)
  self:create_dir(vim.fs.dirname(path))

  local file_path = self.full_path .. path
  local f = io.open(file_path, "w")
  if not f then
    error("cannot open: " .. file_path)
  end
  if content then
    f:write(content)
  end
  f:close()
end

function M.create_dir(self, path)
  vim.fn.mkdir(self.full_path .. path, "p")
end

function M.cd(self, path)
  vim.api.nvim_set_current_dir(self.full_path .. path)
end

local delete = function(target_path)
  local result = vim.fn.delete(target_path, "rf")
  if result == -1 or result == true then
    error("failed to delete: " .. target_path)
  end
end

function M.delete(self, path)
  local target_path = self.full_path .. path
  delete(target_path)
end

function M.teardown(self)
  delete(self._base_path)
end

return M
